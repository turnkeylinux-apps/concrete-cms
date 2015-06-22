Concrete5 - Next generation Content Management System
=====================================================

`Concrete5`_ makes it easy for anyone to run a website with minimal
technical skills. Go to any page in your site, and a editing toolbar
gives you all the controls you need to update your website.  No
intimidating manuals, no complicated administration interfaces - just
point and click.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Concrete5 configurations:
   
   - Installed from upstream source code to /var/www/concrete5

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Credentials *(passwords set at first boot)*
-------------------------------------------

- Webmin, SSH, MySQL, phpMyAdmin: username **root**
- Concrete5: username **admin**


.. _Concrete5: http://www.concrete5.org/
.. _TurnKey Core: http://www.turnkeylinux.org/core
.. _Adminer: http://www.adminer.org/
