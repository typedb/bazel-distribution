<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a id="#assemble_npm"></a>

## assemble_npm

<pre>
assemble_npm(<a href="#assemble_npm-name">name</a>, <a href="#assemble_npm-target">target</a>, <a href="#assemble_npm-version_file">version_file</a>)
</pre>

Assemble `npm_package` target for further deployment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_npm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_npm-target"></a>target |  <code>npm_library</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_npm-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#assemble_pip"></a>

## assemble_pip

<pre>
assemble_pip(<a href="#assemble_pip-name">name</a>, <a href="#assemble_pip-author">author</a>, <a href="#assemble_pip-author_email">author_email</a>, <a href="#assemble_pip-classifiers">classifiers</a>, <a href="#assemble_pip-description">description</a>, <a href="#assemble_pip-install_requires">install_requires</a>, <a href="#assemble_pip-keywords">keywords</a>,
             <a href="#assemble_pip-license">license</a>, <a href="#assemble_pip-long_description_file">long_description_file</a>, <a href="#assemble_pip-package_name">package_name</a>, <a href="#assemble_pip-target">target</a>, <a href="#assemble_pip-url">url</a>, <a href="#assemble_pip-version_file">version_file</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_pip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_pip-author"></a>author |  Details about the author   | String | required |  |
| <a id="assemble_pip-author_email"></a>author_email |  The email for the author   | String | required |  |
| <a id="assemble_pip-classifiers"></a>classifiers |  A list of strings, containing Python package classifiers   | List of strings | required |  |
| <a id="assemble_pip-description"></a>description |  A string with the short description of the package   | String | required |  |
| <a id="assemble_pip-install_requires"></a>install_requires |  A list of strings which are names of required packages for this one   | List of strings | required |  |
| <a id="assemble_pip-keywords"></a>keywords |  A list of strings, containing keywords   | List of strings | required |  |
| <a id="assemble_pip-license"></a>license |  The type of license to use   | String | required |  |
| <a id="assemble_pip-long_description_file"></a>long_description_file |  A label with the long description of the package. Usually a README or README.rst file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_pip-package_name"></a>package_name |  A string with Python pip package name   | String | required |  |
| <a id="assemble_pip-target"></a>target |  <code>py_library</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_pip-url"></a>url |  A homepage for the project   | String | required |  |
| <a id="assemble_pip-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#assemble_versioned"></a>

## assemble_versioned

<pre>
assemble_versioned(<a href="#assemble_versioned-name">name</a>, <a href="#assemble_versioned-targets">targets</a>, <a href="#assemble_versioned-version_file">version_file</a>)
</pre>

Version multiple archives for subsequent simultaneous deployment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_versioned-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_versioned-targets"></a>targets |  Archives to version and put into output archive   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="assemble_versioned-version_file"></a>version_file |  File containing version string   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#checksum"></a>

## checksum

<pre>
checksum(<a href="#checksum-name">name</a>, <a href="#checksum-archive">archive</a>)
</pre>

Computes SHA256 checksum of file

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="checksum-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="checksum-archive"></a>archive |  Archive to compute checksum of   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_apt"></a>

## deploy_apt

<pre>
deploy_apt(<a href="#deploy_apt-name">name</a>, <a href="#deploy_apt-deployment_properties">deployment_properties</a>, <a href="#deploy_apt-target">target</a>)
</pre>

Deploy package built with `assemble_apt` to APT repository

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_apt-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_apt-deployment_properties"></a>deployment_properties |  Properties file containing repo.apt.(snapshot|release) key   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_apt-target"></a>target |  assemble_apt label to deploy   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_brew"></a>

## deploy_brew

<pre>
deploy_brew(<a href="#deploy_brew-name">name</a>, <a href="#deploy_brew-checksum">checksum</a>, <a href="#deploy_brew-deployment_properties">deployment_properties</a>, <a href="#deploy_brew-formula">formula</a>, <a href="#deploy_brew-type">type</a>, <a href="#deploy_brew-version_file">version_file</a>)
</pre>

Deploy Homebrew (Caskroom) formula to Homebrew tap

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_brew-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_brew-checksum"></a>checksum |  Checksum of deployed artifact   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_brew-deployment_properties"></a>deployment_properties |  Properties file containing repo.brew.(snapshot|release) key   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_brew-formula"></a>formula |  The brew formula definition   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_brew-type"></a>type |  Type of deployment (Homebrew/Caskroom).             Cask is generally used for graphic applications   | String | optional | "brew" |
| <a id="deploy_brew-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_github"></a>

## deploy_github

<pre>
deploy_github(<a href="#deploy_github-name">name</a>, <a href="#deploy_github-archive">archive</a>, <a href="#deploy_github-deployment_properties">deployment_properties</a>, <a href="#deploy_github-release_description">release_description</a>, <a href="#deploy_github-title">title</a>,
              <a href="#deploy_github-title_append_version">title_append_version</a>, <a href="#deploy_github-version_file">version_file</a>)
</pre>

Deploy `assemble_versioned` target to GitHub Releases

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_github-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_github-archive"></a>archive |  <code>assemble_versioned</code> label to be deployed.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_github-deployment_properties"></a>deployment_properties |  File containing <code>repo.github.organisation</code> and <code>repo.github.repository</code> keys   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_github-release_description"></a>release_description |  Description of GitHub release   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_github-title"></a>title |  Title of GitHub release   | String | optional | "" |
| <a id="deploy_github-title_append_version"></a>title_append_version |  Append version to GitHub release title   | Boolean | optional | False |
| <a id="deploy_github-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_npm"></a>

## deploy_npm

<pre>
deploy_npm(<a href="#deploy_npm-name">name</a>, <a href="#deploy_npm-deployment_properties">deployment_properties</a>, <a href="#deploy_npm-target">target</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_npm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_npm-deployment_properties"></a>deployment_properties |  File containing Node repository url by <code>repo.npm</code> key   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_npm-target"></a>target |  <code>assemble_npm</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_packer"></a>

## deploy_packer

<pre>
deploy_packer(<a href="#deploy_packer-name">name</a>, <a href="#deploy_packer-target">target</a>)
</pre>

Execute Packer to perform deployment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_packer-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_packer-target"></a>target |  <code>assemble_packer</code> label to be deployed.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_pip"></a>

## deploy_pip

<pre>
deploy_pip(<a href="#deploy_pip-name">name</a>, <a href="#deploy_pip-deployment_properties">deployment_properties</a>, <a href="#deploy_pip-target">target</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_pip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_pip-deployment_properties"></a>deployment_properties |  File containing Python pip repository url by <code>repo.pypi</code> key   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_pip-target"></a>target |  <code>assemble_pip</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_rpm"></a>

## deploy_rpm

<pre>
deploy_rpm(<a href="#deploy_rpm-name">name</a>, <a href="#deploy_rpm-deployment_properties">deployment_properties</a>, <a href="#deploy_rpm-target">target</a>)
</pre>

Deploy package built with `assemble_rpm` to RPM repository

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_rpm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_rpm-deployment_properties"></a>deployment_properties |  Properties file containing repo.rpm.(snapshot|release) key   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_rpm-target"></a>target |  <code>assemble_rpm</code> target to deploy   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#generate_json_config"></a>

## generate_json_config

<pre>
generate_json_config(<a href="#generate_json_config-name">name</a>, <a href="#generate_json_config-substitutions">substitutions</a>, <a href="#generate_json_config-template">template</a>)
</pre>

Fills in JSON template with provided values

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate_json_config-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="generate_json_config-substitutions"></a>substitutions |  Values to fill in   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="generate_json_config-template"></a>template |  JSON template to fill in values   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#java_deps"></a>

## java_deps

<pre>
java_deps(<a href="#java_deps-name">name</a>, <a href="#java_deps-java_deps_root">java_deps_root</a>, <a href="#java_deps-maven_name">maven_name</a>, <a href="#java_deps-target">target</a>, <a href="#java_deps-version_file">version_file</a>)
</pre>

Packs Java library alongside with its dependencies into archive

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="java_deps-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="java_deps-java_deps_root"></a>java_deps_root |  Folder inside archive to put JARs into   | String | optional | "" |
| <a id="java_deps-maven_name"></a>maven_name |  Name JAR files inside archive based on Maven coordinates   | Boolean | optional | False |
| <a id="java_deps-target"></a>target |  Java target to pack into archive   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="java_deps-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#tgz2zip"></a>

## tgz2zip

<pre>
tgz2zip(<a href="#tgz2zip-name">name</a>, <a href="#tgz2zip-output_filename">output_filename</a>, <a href="#tgz2zip-prefix">prefix</a>, <a href="#tgz2zip-prefix_file">prefix_file</a>, <a href="#tgz2zip-tgz">tgz</a>)
</pre>

Converts .tar.gz into .zip

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tgz2zip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tgz2zip-output_filename"></a>output_filename |  Resulting filename   | String | required |  |
| <a id="tgz2zip-prefix"></a>prefix |  Prefix of files in archive   | String | optional | "" |
| <a id="tgz2zip-prefix_file"></a>prefix_file |  Prefix of files in archive (as a file)   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="tgz2zip-tgz"></a>tgz |  Input .tar.gz archive   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#JarToMavenCoordinatesMapping"></a>

## JarToMavenCoordinatesMapping

<pre>
JarToMavenCoordinatesMapping(<a href="#JarToMavenCoordinatesMapping-filename">filename</a>, <a href="#JarToMavenCoordinatesMapping-maven_coordinates">maven_coordinates</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="JarToMavenCoordinatesMapping-filename"></a>filename |  jar filename    |
| <a id="JarToMavenCoordinatesMapping-maven_coordinates"></a>maven_coordinates |  Maven coordinates of the jar    |


<a id="#TransitiveJarToMavenCoordinatesMapping"></a>

## TransitiveJarToMavenCoordinatesMapping

<pre>
TransitiveJarToMavenCoordinatesMapping(<a href="#TransitiveJarToMavenCoordinatesMapping-mapping">mapping</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="TransitiveJarToMavenCoordinatesMapping-mapping"></a>mapping |  maps jar filename to coordinates    |


<a id="#assemble_apt"></a>

## assemble_apt

<pre>
assemble_apt(<a href="#assemble_apt-name">name</a>, <a href="#assemble_apt-package_name">package_name</a>, <a href="#assemble_apt-maintainer">maintainer</a>, <a href="#assemble_apt-description">description</a>, <a href="#assemble_apt-version_file">version_file</a>, <a href="#assemble_apt-installation_dir">installation_dir</a>,
             <a href="#assemble_apt-workspace_refs">workspace_refs</a>, <a href="#assemble_apt-archives">archives</a>, <a href="#assemble_apt-empty_dirs">empty_dirs</a>, <a href="#assemble_apt-files">files</a>, <a href="#assemble_apt-depends">depends</a>, <a href="#assemble_apt-symlinks">symlinks</a>, <a href="#assemble_apt-permissions">permissions</a>)
</pre>

Assemble package for installation with APT

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_apt-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_apt-package_name"></a>package_name |  Package name for built .deb package     https://www.debian.org/doc/debian-policy/ch-controlfields#package   |  none |
| <a id="assemble_apt-maintainer"></a>maintainer |  The package maintainer's name and email address.     The name must come first, then the email address     inside angle brackets &lt;&gt; (in RFC822 format)   |  none |
| <a id="assemble_apt-description"></a>description |  description of the built package     https://www.debian.org/doc/debian-policy/ch-controlfields#description   |  none |
| <a id="assemble_apt-version_file"></a>version_file |  File containing version number of a package.     Alternatively, pass --define version=VERSION to Bazel invocation.     Specifying commit SHA will result in prepending '0.0.0' to it to comply with Debian rules.     Not specifying version at all defaults to '0.0.0'     https://www.debian.org/doc/debian-policy/ch-controlfields#version   |  <code>None</code> |
| <a id="assemble_apt-installation_dir"></a>installation_dir |  directory into which .deb package is unpacked at installation   |  <code>None</code> |
| <a id="assemble_apt-workspace_refs"></a>workspace_refs |  JSON file with other Bazel workspace references   |  <code>None</code> |
| <a id="assemble_apt-archives"></a>archives |  Bazel labels of archives that go into .deb package   |  <code>[]</code> |
| <a id="assemble_apt-empty_dirs"></a>empty_dirs |  list of empty directories created at package installation   |  <code>[]</code> |
| <a id="assemble_apt-files"></a>files |  mapping between Bazel labels of archives that go into .deb package     and their resulting location on .deb package installation   |  <code>{}</code> |
| <a id="assemble_apt-depends"></a>depends |  list of Debian packages this package depends on     https://www.debian.org/doc/debian-policy/ch-relationships.htm   |  <code>[]</code> |
| <a id="assemble_apt-symlinks"></a>symlinks |  mapping between source and target of symbolic links     created at installation   |  <code>{}</code> |
| <a id="assemble_apt-permissions"></a>permissions |  mapping between paths and UNIX permissions   |  <code>{}</code> |


<a id="#assemble_aws"></a>

## assemble_aws

<pre>
assemble_aws(<a href="#assemble_aws-name">name</a>, <a href="#assemble_aws-ami_name">ami_name</a>, <a href="#assemble_aws-install">install</a>, <a href="#assemble_aws-region">region</a>, <a href="#assemble_aws-files">files</a>)
</pre>

Assemble files for AWS deployment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_aws-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_aws-ami_name"></a>ami_name |  AMI name of deployed image   |  none |
| <a id="assemble_aws-install"></a>install |  Bazel label for install file   |  none |
| <a id="assemble_aws-region"></a>region |  AWS region to deploy image to   |  none |
| <a id="assemble_aws-files"></a>files |  Files to include into AWS deployment   |  none |


<a id="#assemble_azure"></a>

## assemble_azure

<pre>
assemble_azure(<a href="#assemble_azure-name">name</a>, <a href="#assemble_azure-image_name">image_name</a>, <a href="#assemble_azure-resource_group_name">resource_group_name</a>, <a href="#assemble_azure-install">install</a>, <a href="#assemble_azure-files">files</a>)
</pre>

Assemble files for GCP deployment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_azure-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_azure-image_name"></a>image_name |  name of deployed image   |  none |
| <a id="assemble_azure-resource_group_name"></a>resource_group_name |  name of the resource group to place image in   |  none |
| <a id="assemble_azure-install"></a>install |  Bazel label for install file   |  none |
| <a id="assemble_azure-files"></a>files |  Files to include into Azure deployment   |  <code>None</code> |


<a id="#assemble_gcp"></a>

## assemble_gcp

<pre>
assemble_gcp(<a href="#assemble_gcp-name">name</a>, <a href="#assemble_gcp-project_id">project_id</a>, <a href="#assemble_gcp-install">install</a>, <a href="#assemble_gcp-zone">zone</a>, <a href="#assemble_gcp-image_name">image_name</a>, <a href="#assemble_gcp-image_family">image_family</a>, <a href="#assemble_gcp-files">files</a>, <a href="#assemble_gcp-image_licenses">image_licenses</a>,
             <a href="#assemble_gcp-disable_default_service_account">disable_default_service_account</a>, <a href="#assemble_gcp-source_image_family">source_image_family</a>)
</pre>

Assemble files for GCP deployment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_gcp-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_gcp-project_id"></a>project_id |  Google project id   |  none |
| <a id="assemble_gcp-install"></a>install |  Bazel label for install file   |  none |
| <a id="assemble_gcp-zone"></a>zone |  GCP zone to deploy image to   |  none |
| <a id="assemble_gcp-image_name"></a>image_name |  name of deployed image   |  none |
| <a id="assemble_gcp-image_family"></a>image_family |  family of deployed image   |  <code>""</code> |
| <a id="assemble_gcp-files"></a>files |  Files to include into GCP deployment   |  <code>None</code> |
| <a id="assemble_gcp-image_licenses"></a>image_licenses |  licenses to attach to deployed image   |  <code>None</code> |
| <a id="assemble_gcp-disable_default_service_account"></a>disable_default_service_account |  disable default service account   |  <code>False</code> |
| <a id="assemble_gcp-source_image_family"></a>source_image_family |  Family of GCP base image   |  <code>"ubuntu-1604-lts"</code> |


<a id="#assemble_packer"></a>

## assemble_packer

<pre>
assemble_packer(<a href="#assemble_packer-name">name</a>, <a href="#assemble_packer-config">config</a>, <a href="#assemble_packer-files">files</a>)
</pre>

Assemble files for HashiCorp Packer deployment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_packer-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_packer-config"></a>config |  Packer JSON config   |  none |
| <a id="assemble_packer-files"></a>files |  Files to include into deployment   |  <code>{}</code> |


<a id="#assemble_rpm"></a>

## assemble_rpm

<pre>
assemble_rpm(<a href="#assemble_rpm-name">name</a>, <a href="#assemble_rpm-package_name">package_name</a>, <a href="#assemble_rpm-spec_file">spec_file</a>, <a href="#assemble_rpm-version_file">version_file</a>, <a href="#assemble_rpm-workspace_refs">workspace_refs</a>, <a href="#assemble_rpm-installation_dir">installation_dir</a>,
             <a href="#assemble_rpm-archives">archives</a>, <a href="#assemble_rpm-empty_dirs">empty_dirs</a>, <a href="#assemble_rpm-files">files</a>, <a href="#assemble_rpm-permissions">permissions</a>, <a href="#assemble_rpm-symlinks">symlinks</a>, <a href="#assemble_rpm-tags">tags</a>)
</pre>

Assemble package for installation with RPM

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_rpm-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_rpm-package_name"></a>package_name |  Package name for built .rpm package   |  none |
| <a id="assemble_rpm-spec_file"></a>spec_file |  The RPM spec file to use   |  none |
| <a id="assemble_rpm-version_file"></a>version_file |  File containing version number of a package.     Alternatively, pass --define version=VERSION to Bazel invocation.     Not specifying version defaults to '0.0.0'   |  <code>None</code> |
| <a id="assemble_rpm-workspace_refs"></a>workspace_refs |  JSON file with other Bazel workspace references   |  <code>None</code> |
| <a id="assemble_rpm-installation_dir"></a>installation_dir |  directory into which .rpm package is unpacked at installation   |  <code>None</code> |
| <a id="assemble_rpm-archives"></a>archives |  Bazel labels of archives that go into .rpm package   |  <code>[]</code> |
| <a id="assemble_rpm-empty_dirs"></a>empty_dirs |  list of empty directories created at package installation   |  <code>[]</code> |
| <a id="assemble_rpm-files"></a>files |  mapping between Bazel labels of archives that go into .rpm package     and their resulting location on .rpm package installation   |  <code>{}</code> |
| <a id="assemble_rpm-permissions"></a>permissions |  mapping between paths and UNIX permissions   |  <code>{}</code> |
| <a id="assemble_rpm-symlinks"></a>symlinks |  mapping between source and target of symbolic links             created at installation   |  <code>{}</code> |
| <a id="assemble_rpm-tags"></a>tags |  additional tags passed to all wrapped rules   |  <code>[]</code> |


<a id="#assemble_targz"></a>

## assemble_targz

<pre>
assemble_targz(<a href="#assemble_targz-name">name</a>, <a href="#assemble_targz-output_filename">output_filename</a>, <a href="#assemble_targz-targets">targets</a>, <a href="#assemble_targz-additional_files">additional_files</a>, <a href="#assemble_targz-empty_directories">empty_directories</a>, <a href="#assemble_targz-permissions">permissions</a>,
               <a href="#assemble_targz-append_version">append_version</a>, <a href="#assemble_targz-visibility">visibility</a>, <a href="#assemble_targz-tags">tags</a>)
</pre>

Assemble distribution archive (.tar.gz)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_targz-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_targz-output_filename"></a>output_filename |  filename of resulting archive   |  <code>None</code> |
| <a id="assemble_targz-targets"></a>targets |  Bazel labels of archives that go into .tar.gz package   |  <code>[]</code> |
| <a id="assemble_targz-additional_files"></a>additional_files |  mapping between Bazel labels of files that go into archive     and their resulting location in archive   |  <code>{}</code> |
| <a id="assemble_targz-empty_directories"></a>empty_directories |  list of empty directories created at archive installation   |  <code>[]</code> |
| <a id="assemble_targz-permissions"></a>permissions |  mapping between paths and UNIX permissions   |  <code>{}</code> |
| <a id="assemble_targz-append_version"></a>append_version |  append version to root folder inside the archive   |  <code>True</code> |
| <a id="assemble_targz-visibility"></a>visibility |  controls whether the target can be used by other packages   |  <code>["//visibility:private"]</code> |
| <a id="assemble_targz-tags"></a>tags |  <p align="center"> - </p>   |  <code>[]</code> |


<a id="#assemble_zip"></a>

## assemble_zip

<pre>
assemble_zip(<a href="#assemble_zip-name">name</a>, <a href="#assemble_zip-output_filename">output_filename</a>, <a href="#assemble_zip-targets">targets</a>, <a href="#assemble_zip-additional_files">additional_files</a>, <a href="#assemble_zip-empty_directories">empty_directories</a>, <a href="#assemble_zip-permissions">permissions</a>,
             <a href="#assemble_zip-append_version">append_version</a>, <a href="#assemble_zip-visibility">visibility</a>)
</pre>

Assemble distribution archive (.zip)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_zip-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_zip-output_filename"></a>output_filename |  filename of resulting archive   |  none |
| <a id="assemble_zip-targets"></a>targets |  Bazel labels of archives that go into .tar.gz package   |  none |
| <a id="assemble_zip-additional_files"></a>additional_files |  mapping between Bazel labels of files that go into archive     and their resulting location in archive   |  <code>{}</code> |
| <a id="assemble_zip-empty_directories"></a>empty_directories |  list of empty directories created at archive installation   |  <code>[]</code> |
| <a id="assemble_zip-permissions"></a>permissions |  mapping between paths and UNIX permissions   |  <code>{}</code> |
| <a id="assemble_zip-append_version"></a>append_version |  append version to root folder inside the archive   |  <code>True</code> |
| <a id="assemble_zip-visibility"></a>visibility |  controls whether the target can be used by other packages   |  <code>["//visibility:private"]</code> |


