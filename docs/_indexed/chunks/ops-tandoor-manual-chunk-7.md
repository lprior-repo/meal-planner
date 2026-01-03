---
doc_id: ops/tandoor/manual
chunk_id: ops/tandoor/manual#chunk-7
heading_path: ["Manual installation instructions", "... no root privileges"]
chunk_type: code
tokens: 183
summary: "... no root privileges"
---

## ... no root privileges
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
```text
```shell
sudo npm install --global yarn
```text

!!! info "NodeJS installation issues"
    If you run into problems with the NodeJS installation, please refer to the [official documentation](https://github.com/nodesource/distributions/blob/master/README.md).

### Install postgresql requirements

```shell
sudo apt install -y libpq-dev postgresql
```text

### Install LDAP requirements

```shell
sudo apt install -y libsasl2-dev python3-dev libldap2-dev libssl-dev
```text

### Install project requirements

!!! warning "Update"
    Dependencies change with most updates so the following steps need to be re-run with every update or else the application might stop working.
    See section [Updating](#updating) below.

Using binaries from the virtual env:

```shell
/var/www/recipes/bin/pip3 install -r requirements.txt
```text

You will also need to install front end requirements and build them. For this navigate to the `./vue3` folder and run

```shell
cd ./vue3
yarn install
yarn build
```text
