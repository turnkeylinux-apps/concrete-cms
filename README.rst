Concrete CMS - Next generation Content Management System
=====================================================

`Concrete CMS`_ makes it easy for anyone to run a website with minimal
technical skills. Go to any page in your site, and a editing toolbar
gives you all the controls you need to update your website.  No
intimidating manuals, no complicated administration interfaces - just
point and click.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Concrete CMS configurations:
   
   - Installed (using composer_) to /var/www/concrete

     **Security note**: Updates to Concrete CMS may require supervision so
     they **ARE NOT** configured to install automatically. See `Concrete CMS
     documentation`_ for upgrading.

   - Includes `concrete (cli)`_ and composer_ for command line administration,
     configuration and development. Also includes relevant
     wrapper scripts; turnkey-concrete_, turnkey-composer_ (run
     the relevant command, but as www-data user).


- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

- Webmin, SSH, MySQL: username **root**
- Adminer: username **adminer**
- Concrete CMS: username **admin**


.. _Concrete CMS: https://www.concretecms.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Concrete CMS documentation: https://documentation.concretecms.org/developers/introduction/installing-concrete-cms/upgrading-concrete
.. _composer: https://getcomposer.org/
.. _concrete (cli): https://documentation.concretecms.org/developers/framework/console-commands-and-jobs/command-line-interface-cli-commands
.. _turnkey-concrete: https://github.com/turnkeylinux-apps/concrete-cms/blob/master/overlay/usr/local/bin/turnkey-concrete
.. _turnkey-composer: https://github.com/turnkeylinux/common/blob/master/overlays/composer/usr/local/bin/turnkey-composer
.. _Adminer: https://www.adminer.org/
