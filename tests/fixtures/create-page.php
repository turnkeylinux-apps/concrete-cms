<?php

use Concrete\Core\Block\BlockType\BlockType;
use Concrete\Core\Page\Page;
use Concrete\Core\Page\Template;
use Concrete\Core\Page\Type\Type;

$options = getopt('', ['name:', 'handle:', 'content:']);
$name = $options['name'] ?? '';
$handle = $options['handle'] ?? '';
$content = $options['content'] ?? '';

if ($name === '' || $content === '' || !preg_match('/^[a-z0-9-]+$/', $handle)) {
    fwrite(STDERR, "name, content and a URL-safe handle are required\n");
    exit(2);
}

$webroot = '/var/www/concrete/public';
$_SERVER['SCRIPT_FILENAME'] = "$webroot/index.php";
$_SERVER['PHP_SELF'] = 'tkl-v19-create-page.php';

require "$webroot/concrete/bootstrap/configure.php";
require "$webroot/concrete/bootstrap/autoload.php";
$app = require "$webroot/concrete/bootstrap/start.php";

$site = $app->make('site')->getDefault();
$parent = $site ? $site->getSiteHomePageObject() : null;
$pageType = Type::getByHandle('page');
$pageTemplate = Template::getByHandle('full');
$blockType = BlockType::getByHandle('html');

if (!$parent || !$pageType || !$pageTemplate || !$blockType) {
    throw new RuntimeException('The installed site is missing its standard page components.');
}

$page = $parent->add($pageType, [
    'cName' => $name,
    'cHandle' => $handle,
    'cDescription' => 'TurnKey v19 acceptance page',
    'uID' => USER_SUPER_ID,
    'cvIsApproved' => true,
], $pageTemplate);
$page->addBlock($blockType, 'Main', [
    'content' => '<p id="tkl-v19-acceptance">' . h($content) . '</p>',
]);

echo $page->getCollectionID(), "\n";
$app->shutdown();
