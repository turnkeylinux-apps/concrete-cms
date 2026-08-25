#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
app_password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
db_password=${TKL_TEST_DB_PASS:?TKL_TEST_DB_PASS is required}
base=https://127.0.0.1
cookie=/tmp/tkl-concrete-cookie.$$
page=/tmp/tkl-concrete-page.$$
headers=/tmp/tkl-concrete-headers.$$
policy=/tmp/tkl-concrete-policy.$$
release=/tmp/tkl-concrete-release.$$

report_error() {
    printf 'test_failure line=%s status=%s command=%q\n' \
        "$1" "$2" "$3" >&2
    exit "$2"
}
trap 'report_error "$LINENO" "$?" "$BASH_COMMAND"' ERR

cleanup() {
    rm -f -- "$cookie" "$page" "$headers" "$policy" "$release"
}
trap cleanup EXIT

csrf_token() {
    python3 - "$1" <<'PYTHON'
import re
import sys

page = open(sys.argv[1], encoding="utf-8").read()
tag = re.search(r'<input[^>]+name="ccm_token"[^>]*>', page)
assert tag, "Concrete CMS login page did not contain a CSRF field"
value = re.search(r'value="([^"]+)"', tag.group(0))
assert value, "Concrete CMS CSRF field had no value"
print(value.group(1))
PYTHON
}

systemctl --quiet is-active apache2.service mariadb.service postfix.service \
    cron.service multi-user.target
systemctl --quiet is-enabled apache2.service mariadb.service postfix.service \
    cron.service
apache2ctl -t
apache2ctl -M 2>/dev/null | grep -q ' rewrite_module '
grep -Fxq 'VERSION_CODENAME=trixie' /etc/os-release
grep -Eq '^turnkey-concrete-cms-19\.0' /etc/turnkey_version

# shellcheck disable=SC1091
. /usr/local/share/concrete-cms-release
: "${CONCRETE_CMS_VERSION:?}"
: "${CONCRETE_CMS_TAG:?}"
: "${CONCRETE_CMS_COMMIT:?}"
: "${CONCRETE_CMS_SOURCE_SHA256:?}"
test "$CONCRETE_CMS_VERSION" = 9.5.2
test "$CONCRETE_CMS_TAG" = 9.5.2
test "$CONCRETE_CMS_COMMIT" = 72f0bf37601073e29b279415be8ea2b6af06efac
test "$CONCRETE_CMS_SOURCE_SHA256" = \
    44ba6f6f23ae19b936f6df9652af07590ef2da64933f24095a9a5e807ce553bb
grep -Fq "'version' => '9.5.2'" \
    /var/www/concrete/public/concrete/config/concrete.php
turnkey-concrete c5:is-installed

php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
test "$php_version" = 8.4
for module in curl dom gd intl mbstring mysqli pdo_mysql SimpleXML zip; do
    php -m | grep -Fxiq "$module"
done
composer_version=$(dpkg-query -W -f='${Version}' composer)
mariadb_version=$(dpkg-query -W -f='${Version}' mariadb-server)
apache_version=$(dpkg-query -W -f='${Version}' apache2)

curl --insecure --fail --silent --show-error "$base/" >"$page"
grep -Fq 'TurnKey-Concrete-CMS' "$page"
curl --insecure --fail --silent --show-error \
    --cookie-jar "$cookie" "$base/login" >"$page"
grep -qi 'Sign in' "$page"
token=$(csrf_token "$page")
curl --insecure --silent --show-error \
    --cookie "$cookie" --cookie-jar "$cookie" \
    --data-urlencode "ccm_token=$token" \
    --data-urlencode 'uName=admin' \
    --data-urlencode "uPassword=$app_password" \
    --dump-header "$headers" --output "$page" \
    "$base/login/authenticate/concrete"
grep -q '^HTTP/.* 302' "$headers"
curl --insecure --fail --silent --show-error --location \
    --cookie "$cookie" --cookie-jar "$cookie" "$base/dashboard" >"$page"
grep -qi 'Dashboard' "$page"
grep -qi 'Sign Out' "$page"
test "$(mariadb --batch --skip-column-names --user=root \
    --password="$db_password" --execute \
    'SELECT uEmail FROM concrete.Users WHERE uName="admin"')" = \
    admin@example.invalid

page_handle="tkl-v19-acceptance-$RANDOM-$$"
page_name="TurnKey v19 acceptance page $$"
page_content="Concrete CMS page content round trip $$"
page_id=$(runuser -u www-data -- php \
    /run/tkl-v19-tests/tests/fixtures/create-page.php \
    --name "$page_name" --handle "$page_handle" --content "$page_content")
test "$page_id" -gt 0
curl --insecure --fail --silent --show-error \
    "$base/$page_handle" >"$page"
grep -Fq "$page_name" "$page"
grep -Fq "$page_content" "$page"
db_page_id=$(mariadb --batch --skip-column-names --user=root \
    --password="$db_password" --execute \
    "SELECT cID FROM concrete.PagePaths WHERE cPath='/$page_handle'")
test "$db_page_id" = "$page_id"
mariadb --batch --skip-column-names --user=root \
    --password="$db_password" --execute \
    "SELECT cvName FROM concrete.CollectionVersions WHERE cID=$page_id ORDER BY cvID DESC LIMIT 1" |
    grep -Fxq "$page_name"
mariadb --batch --skip-column-names --user=root \
    --password="$db_password" --execute \
    "SELECT content FROM concrete.btContentLocal WHERE content LIKE '%$page_content%'" |
    grep -Fq "$page_content"
systemctl restart mariadb.service
curl --insecure --fail --silent --show-error \
    "$base/$page_handle" >"$page"
grep -Fq "$page_content" "$page"

grep -Fq '/usr/local/bin/turnkey-concrete concrete:scheduler:run' \
    /etc/cron.d/concrete-cms
turnkey-concrete c5:sitemap:generate --url="$base"
test -s /var/www/concrete/public/sitemap.xml
grep -q '<urlset' /var/www/concrete/public/sitemap.xml
turnkey-concrete concrete:scheduler:run

curl --insecure --fail --silent --show-error \
    https://127.0.0.1:12322/ | grep -qi Adminer
curl --insecure --fail --silent --show-error \
    https://127.0.0.1:12321/ >/dev/null

turnkey-concrete c5:update --help | grep -q 'Update Concrete'
curl --fail --silent --show-error \
    https://api.github.com/repos/concretecms/concretecms/releases/latest \
    >"$release"
latest=$(python3 - "$release" <<'PYTHON'
import json
import re
import sys

release = json.load(open(sys.argv[1], encoding="utf-8"))
version = release["tag_name"]
asset = next(
    item for item in release["assets"]
    if item["name"] == f"concrete-cms-{version}.zip"
)
assert re.fullmatch(r"sha256:[0-9a-f]{64}", asset["digest"])
print(version)
PYTHON
)
test "$(printf '%s\n%s\n' "$CONCRETE_CMS_VERSION" "$latest" | \
    sort -V | tail -n 1)" = "$latest"

before="$composer_version|$mariadb_version|$apache_version"
apt-get update >/dev/null
for package in php composer mariadb-server apache2; do
    apt-cache policy "$package" >"$policy"
    candidate=$(awk '/Candidate:/ {print $2}' "$policy")
    test -n "$candidate"
    test "$candidate" != '(none)'
    grep -Eq 'trixie|deb13' "$policy"
done
after="$(dpkg-query -W -f='${Version}' composer)|$(dpkg-query -W -f='${Version}' mariadb-server)|$(dpkg-query -W -f='${Version}' apache2)"
test "$after" = "$before"
grep -Rqs '^Suites: trixie' /etc/apt/sources.list.d
if grep -Rqi bookworm /etc/apt/sources.list.d; then
    exit 1
fi

cat >"$result" <<EOF
package_source=Debian 13 Trixie APT repositories for PHP 8.4, Composer, Apache and MariaDB; official Concrete CMS 9.5.2 GitHub release asset
installed_version=Concrete CMS $CONCRETE_CMS_VERSION; PHP $php_version; Composer $composer_version; Apache $apache_version; MariaDB $mariadb_version
runtime_checks=normal init; HTTPS site; administrator HTTP login after firstboot; administrator-authored page create and public read with MariaDB readback and restart; Concrete job and scheduler commands; Adminer and Webmin endpoints
updater_command=turnkey-concrete c5:update --help; official GitHub latest-release query; apt-get update and apt-cache policy
updater_result=Concrete CLI update path is available and official release $latest with a published SHA-256 is discoverable without changing the installation; signed Trixie candidates remain eligible
updater_channel=Concrete CMS dashboard and CLI update workflow using official concretecms/concretecms releases; signed Debian Trixie repositories
integrity_evidence=official Concrete CMS 9.5.2 asset SHA-256 44ba6f6f23ae19b936f6df9652af07590ef2da64933f24095a9a5e807ce553bb at tag commit 72f0bf37601073e29b279415be8ea2b6af06efac; GitHub publishes a digest for the current release asset; APT accepted signed Trixie metadata
EOF
