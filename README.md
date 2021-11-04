# MariaDB Tools

*MariaDB Tools* is a collection of advanced command-line tools used by
[MariaDB](http://www.mariadb.com/) support staff to perform a variety of
MariaDB and system tasks that are too difficult or complex to perform manually.

These tools are ideal alternatives to private or "one-off" scripts because
they are professionally developed, formally tested, and fully documented.
They are also fully self-contained, so installation is quick and easy and
no libraries are installed.

## Installing

Official Packages are available via the [MariaDB-Tools Repository](https://mariadb.com/kb/en/mariadb-package-repository-setup-and-usage/).

```
apt install mariadb-tools

yum install mariadb-tools

dnf install mariadb-tools
```

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

[Click Here for Official Documentation](docs/user/index.md)

Alternatively, Run `man mariadb-tools` to see a list of installed tools, then `man tool`
to read the embedded documentation for a specific tool.


