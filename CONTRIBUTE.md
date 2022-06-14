# Contributing guide
## How Can I Contribute?
## Reporting Bugs
Before creating bug reports, please check this list as you might find out that you don't need to create one. When you create a bug report, please include as many details as possible. You can use this template to structure the information.  

### Before Submitting A Bug Report
- Ensure you have carefully read the documentation. MariaDB Tools is forked from Percona Toolkit, a mature project with many settings that covers a wide range options.
- Search for existing bugs in GitHub to see if the problem has already been reported. If it has, add a comment to the existing issue instead of opening a new one.

### How Do I Submit A (Good) Bug Report?
- Explain the problem and include additional details to help others reproduce the problem:
- Use a clear and descriptive title for the issue to identify the problem.
- Describe the exact steps which reproduce the problem, including as many details as possible. Provide examples of the command you used and include context information like language, OS and database versions.
Describe the obtained results and the expected results and, if it is possible, provide examples.

## Submitting fixes
### Create an Issue
If you find a bug, the first step is to create an issue. Whatever the problem is, you’re likely not the only one experiencing it. Others will find your issue helpful, and other developers might help you find the cause and discuss the best solution for it.

#### Tips for creating an issue
- Check if there are any existing issues for your problem. By doing this, we can avoid duplicating efforts, since the issue might have been already reported and if not, you might find useful information on older issues related to the same problem.
- Be clear about what your problem is: which program were you using, what was the expected result and what is the result you are getting. Detail how someone else can reproduce the problem, including examples.
- Include system details like language version, OS, database details or special configurations, etc.
- Paste the error output or logs in your issue or in a Gist.

### Pull Requests
If you fixed a bug or added a new feature – awesome! Open a pull request with the code! Be sure you’ve read any documents on contributing, understand the license and have signed a Contributor Licence Agreement (CLA) if required. Once you’ve submitted a pull request, the maintainers can compare your branch to the existing one and decide whether or not to incorporate (merge) your changes.

### Tips for creating a pull request
- Fork the repository and clone it locally. Connect your local to the original ‘upstream’ repository by adding it as a remote. Pull in changes from ‘upstream’ often so that you stay up to date so that when you submit your pull request, merge conflicts will be less likely.
- Create a branch for your code. Usually it is a good practice to name the branch after the issue ID, like issue-12345.
- Be clear about the problem you fixed or the feature you added. Include explanations and code references to help the maintainers understand what you did.
- Add useful comments to the code to help others understand it.
- Write tests. This is an important step. Run your changes against existing tests and create new ones when needed. Whether tests exist or not, make sure your changes don’t break the existing project.
- Contribute in the style of the project to the best of your abilities. This may mean using indents, semicolons, or comments differently than you would in your own repository, but makes it easier for the maintainer to merge, others to understand and maintain in the future.
- Keep your changes as small as possible and solve only what's reported in the issue. Mixing fixes might be confusing to others and makes testing harder.
- Be as explicit as possible. Avoid using special/internal language variables like $_. Use a variable name that clearly represents the value it holds.
- Write good commit messages. A comment like 'Misc bugfixes' or 'More code added' does not help to understand what's the change about.

### Open Pull Requests
Once you’ve opened a pull request, a discussion will start around your proposed changes. Other contributors and users may chime in, but ultimately the decision is made by the maintainers. You may be asked to make some changes to your pull request, if so, add more commits to your branch and push them – they’ll automatically go into the existing pull request.

# Licensing
Along with the pull request, include a message indicating that the submitted code is your own creation and it can be distributed under the BSD licence. 
  
  
# Setting up the development environment

#### Setting up the source code
To start, fork the Percona Toolkit repo to be able to submit pull requests and clone it locally:
```
mkdir ${HOME}/scripting
git clone https://github.com/<your-username>/mariadb-tools.git ${HOME}/scripting/mariadb-tools.git
```

For testing, we are going to need to have MariaDB with slaves. For that, we already have scripts in the sandbox directory `first-time.sh` which will create the host-specific directories and leverage the docker-compose.yml.

### Set up environment variables
We need these environment variables to run the tests. Probably it is a good idea to add them to your `.bashrc` file.
```
export PERCONA_TOOLKIT_BRANCH=${HOME}/scripting/mariadb-tools
export PERL5LIB=${HOME}/scripting/mariadb-tools/lib
export PERCONA_TOOLKIT_SANDBOX=`which mysql`                         # Due to our decision to rely on containers, this is not used.
```

### Check that all needed tools are correctly installed:
```
util/check-dev-env
```
If not, you will have to either install them via your package manager of preference, or using Perl directly. For example, let's assume that you are missing the `File::Slurp` package (as flagged by a `NA` output from the previous command), you can use:
```
sudo perl -MCPAN -e "shell"
cpan[1]> install File::Slurp
...
```

### Starting the sandbox
```
cd ${PERCONA_TOOLKIT_BRANCH}/sandbox
```
```
sandbox/first-time.sh
```
To stop the MySQL sandbox: `docker-compose down`  

### Running tests
```
cd ${PERCONA_TOOLKIT_BRANCH}/sandbox

# Run all tests
./cleanup.sh && ./first-time.sh && prove -vwm ../t

# Run specific tool tests
./cleanup.sh && ./first-time.sh && prove -vwm ../t/TOOL_NAME_HERE  # (e.g.) ./cleanup.sh && ./first-time.sh && prove -v ../t/mariadb-archiver

# Run specific test of a tool
./cleanup.sh && ./first-time.sh && prove -vwm ../t/TOOL_NAME_HERE/test-file.t
```

# Introducing changes to the toolkit

## Creating a new branch

You should start your own development branch. If you have a GitHub issue assigned, use its number as reference, and add a short description of what work on this branch will do:
```
git checkout -b 32-summary-formatting
```
The first commit should also have the github issue referenced for automation triggers.

## Running the update-modules tool

Whenever you make changes to libraries under lib/, you should make sure that you run the util/update-modules functionality, to make sure that all tools that use these packages will benefit from the new changes. For example, let's say you changed the lib/bash/collect.sh package, you will need to run:
```
cd ${PERCONA_TOOLKIT_BRANCH}
for t in bin/*; do util/update-modules ${t} collect; done
```
Or if you changed the lib/NibbleIterator.pm package:
```
cd ${PERCONA_TOOLKIT_BRANCH}
for t in bin/*; do util/update-modules ${t} NibbleIterator; done
```

## Uploading your branch

Finally, after you run another round of tests and everything is ok, you should upload your branch to your GitHub fork:
```
git push origin 32-summary-formatting
```
And then go to the web UI to create the new pull request (PR) based off of this new branch.
