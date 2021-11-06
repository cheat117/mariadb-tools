# MariaDB Tools

*MariaDB Tools* is a collection of advanced command-line tools used by
[MariaDB](http://www.mariadb.com/) support staff to perform a variety of
MariaDB and system tasks that are too difficult or complex to perform manually.

These tools are ideal alternatives to private or "one-off" scripts because
they are professionally developed, formally tested, and fully documented.
They are also fully self-contained, so installation is quick and easy and
no libraries are installed.

## Installing

MariaDB provides packages for most popular 64-bit Linux distributions via the [MariaDB-Tools Repository](https://mariadb.com/kb/en/mariadb-package-repository-setup-and-usage/):

* Debian 9 ("stretch")
* Debian 10 ("buster")
* Debian 11 ("bullseye")
* Ubuntu 18.04 LTS (Bionic Beaver)
* Ubuntu 20.04 LTS (Focal Fossa)
* Ubuntu 21.04 (Hirsute Hippo)
* Ubuntu 21.10 (Impish Indri)
* Red Hat Enterprise Linux or CentOS 7
* Red Hat Enterprise Linux or CentOS 8

**NOTE:** MariaDB Tools should work on other DEB-based and RPM-based systems
   (for example, Oracle Linux and Amazon Linux AMI),
   but it is tested only on those listed above.

It is recommended to install MariaDB software from official repositories:

1. Configure repositories as described in
   [MariaDB Enterprise Documentation](https://mariadb.com/docs/deploy/installation/#install-repository).

1. Install MariaDB Tools using the corresponding package manager:

   * For Debian or Ubuntu::

      `sudo apt-get install MariaDB-Tools`

   * For RHEL or CentOS::

      `sudo yum install MariaDB-Tools`
      `sudo dnf install MariaDB-Tools`

### Alternative Install Methods

* Download RPM/DEB from MariaDB

You can also download the packages from the
`MariaDB Customer Portal <https://customers.mariadb.com>`_
and install it using tools like ``dpkg`` and ``rpm``,
depending on your system.

If you want to download a specific tool, use the following address:
http://tools.mariadb.com/get

For example, to download the ``mariadb-summary`` tool, run::

 wget tools.mariadb.com/get/mariadb-summary

* From Source

To install all tools from this repo, run:

```
perl Makefile.PL
make
make test
make install
```  

You probably need to be root to `make install`.  On most systems, the tools
are installed in /usr/local/bin.  See the INSTALL file for more information.

**CENTOS 8 INSTALL ISSUE**
--
It has been identified that you must enable the powertools repo in order to install `perl(DateTime::Format::Strptime)`. This package is required to run `mariadb-parted`.

Error Example:
```
Problem: conflicting requests
  - nothing provides perl(DateTime::Format::Strptime) >= 1.54 needed by mariadb-tools-6.0.0rc-1.x86_64
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
```

## Documentation 

[Click Here for Official Documentation](https://mariadb-corporation.github.io/mariadb-tools/index.html)

Alternatively, Run `man mariadb-tools` to see a list of installed tools, then `man tool`
to read the embedded documentation for a specific tool.


