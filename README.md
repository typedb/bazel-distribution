<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a id="#assemble_crate"></a>

## assemble_crate

<pre>
assemble_crate(<a href="#assemble_crate-name">name</a>, <a href="#assemble_crate-authors">authors</a>, <a href="#assemble_crate-categories">categories</a>, <a href="#assemble_crate-deps">deps</a>, <a href="#assemble_crate-description">description</a>, <a href="#assemble_crate-documentation">documentation</a>, <a href="#assemble_crate-homepage">homepage</a>, <a href="#assemble_crate-keywords">keywords</a>,
               <a href="#assemble_crate-license">license</a>, <a href="#assemble_crate-readme_file">readme_file</a>, <a href="#assemble_crate-repository">repository</a>, <a href="#assemble_crate-target">target</a>, <a href="#assemble_crate-version_file">version_file</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_crate-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_crate-authors"></a>authors |  Project authors   | List of strings | optional | [] |
| <a id="assemble_crate-categories"></a>categories |  Project categories   | List of strings | optional | [] |
| <a id="assemble_crate-deps"></a>deps |  Maps external Crate dependency to its version   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="assemble_crate-description"></a>description |  Description of the project   | String | optional | "" |
| <a id="assemble_crate-documentation"></a>documentation |  Link to documentation of the project   | String | optional | "" |
| <a id="assemble_crate-homepage"></a>homepage |  Link to homepage of the project   | String | optional | "" |
| <a id="assemble_crate-keywords"></a>keywords |  Project keywords   | List of strings | optional | [] |
| <a id="assemble_crate-license"></a>license |  License of the project   | String | optional | "" |
| <a id="assemble_crate-readme_file"></a>readme_file |  README of the project   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="assemble_crate-repository"></a>repository |  Repository of the project   | String | optional | "" |
| <a id="assemble_crate-target"></a>target |  <code>rust_library</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_crate-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#assemble_maven"></a>

## assemble_maven

<pre>
assemble_maven(<a href="#assemble_maven-name">name</a>, <a href="#assemble_maven-license">license</a>, <a href="#assemble_maven-project_description">project_description</a>, <a href="#assemble_maven-project_name">project_name</a>, <a href="#assemble_maven-project_url">project_url</a>, <a href="#assemble_maven-scm_url">scm_url</a>, <a href="#assemble_maven-target">target</a>,
               <a href="#assemble_maven-version_file">version_file</a>, <a href="#assemble_maven-version_overrides">version_overrides</a>, <a href="#assemble_maven-workspace_refs">workspace_refs</a>)
</pre>

Assemble Java package for subsequent deployment to Maven repo

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_maven-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_maven-license"></a>license |  Project license to fill into pom.xml   | String | optional | "apache" |
| <a id="assemble_maven-project_description"></a>project_description |  Project description to fill into pom.xml   | String | optional | "PROJECT_DESCRIPTION" |
| <a id="assemble_maven-project_name"></a>project_name |  Project name to fill into pom.xml   | String | optional | "PROJECT_NAME" |
| <a id="assemble_maven-project_url"></a>project_url |  Project URL to fill into pom.xml   | String | optional | "PROJECT_URL" |
| <a id="assemble_maven-scm_url"></a>scm_url |  Project source control URL to fill into pom.xml   | String | optional | "PROJECT_URL" |
| <a id="assemble_maven-target"></a>target |  Java target for subsequent deployment   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_maven-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="assemble_maven-version_overrides"></a>version_overrides |  Dictionary of maven artifact : version to pin artifact versions to   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="assemble_maven-workspace_refs"></a>workspace_refs |  JSON file describing dependencies to other Bazel workspaces   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#assemble_npm"></a>

## assemble_npm

<pre>
assemble_npm(<a href="#assemble_npm-name">name</a>, <a href="#assemble_npm-target">target</a>, <a href="#assemble_npm-version_file">version_file</a>)
</pre>

Assemble `npm_package` target for further deployment. Currently does not support remote execution (RBE).

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_npm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_npm-target"></a>target |  <code>npm_library</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_npm-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#assemble_pip"></a>

## assemble_pip

<pre>
assemble_pip(<a href="#assemble_pip-name">name</a>, <a href="#assemble_pip-author">author</a>, <a href="#assemble_pip-author_email">author_email</a>, <a href="#assemble_pip-classifiers">classifiers</a>, <a href="#assemble_pip-description">description</a>, <a href="#assemble_pip-keywords">keywords</a>, <a href="#assemble_pip-license">license</a>,
             <a href="#assemble_pip-long_description_file">long_description_file</a>, <a href="#assemble_pip-package_name">package_name</a>, <a href="#assemble_pip-requirements_file">requirements_file</a>, <a href="#assemble_pip-target">target</a>, <a href="#assemble_pip-url">url</a>, <a href="#assemble_pip-version_file">version_file</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="assemble_pip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="assemble_pip-author"></a>author |  Details about the author   | String | required |  |
| <a id="assemble_pip-author_email"></a>author_email |  The email for the author   | String | required |  |
| <a id="assemble_pip-classifiers"></a>classifiers |  A list of strings, containing Python package classifiers   | List of strings | required |  |
| <a id="assemble_pip-description"></a>description |  A string with the short description of the package   | String | required |  |
| <a id="assemble_pip-keywords"></a>keywords |  A list of strings, containing keywords   | List of strings | required |  |
| <a id="assemble_pip-license"></a>license |  The type of license to use   | String | required |  |
| <a id="assemble_pip-long_description_file"></a>long_description_file |  A label with the long description of the package. Usually a README or README.rst file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="assemble_pip-package_name"></a>package_name |  A string with Python pip package name   | String | required |  |
| <a id="assemble_pip-requirements_file"></a>requirements_file |  A file with the list of required packages for this one   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
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
deploy_apt(<a href="#deploy_apt-name">name</a>, <a href="#deploy_apt-release">release</a>, <a href="#deploy_apt-snapshot">snapshot</a>, <a href="#deploy_apt-target">target</a>)
</pre>

Deploy package built with `assemble_apt` to APT repository

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_apt-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_apt-release"></a>release |  Release repository to deploy apt artifact to   | String | required |  |
| <a id="deploy_apt-snapshot"></a>snapshot |  Snapshot repository to deploy apt artifact to   | String | required |  |
| <a id="deploy_apt-target"></a>target |  assemble_apt label to deploy   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_brew"></a>

## deploy_brew

<pre>
deploy_brew(<a href="#deploy_brew-name">name</a>, <a href="#deploy_brew-checksum">checksum</a>, <a href="#deploy_brew-formula">formula</a>, <a href="#deploy_brew-release">release</a>, <a href="#deploy_brew-snapshot">snapshot</a>, <a href="#deploy_brew-type">type</a>, <a href="#deploy_brew-version_file">version_file</a>)
</pre>

Deploy Homebrew (Caskroom) formula to Homebrew tap

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_brew-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_brew-checksum"></a>checksum |  Checksum of deployed artifact   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_brew-formula"></a>formula |  The brew formula definition   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="deploy_brew-release"></a>release |  Release repository to deploy brew artifact to   | String | required |  |
| <a id="deploy_brew-snapshot"></a>snapshot |  Snapshot repository to deploy brew artifact to   | String | required |  |
| <a id="deploy_brew-type"></a>type |  Type of deployment (Homebrew/Caskroom).             Cask is generally used for graphic applications   | String | optional | "brew" |
| <a id="deploy_brew-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_crate"></a>

## deploy_crate

<pre>
deploy_crate(<a href="#deploy_crate-name">name</a>, <a href="#deploy_crate-release">release</a>, <a href="#deploy_crate-snapshot">snapshot</a>, <a href="#deploy_crate-target">target</a>)
</pre>

Deploy `assemble_crate` target into Crate repo

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_crate-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_crate-release"></a>release |  Release repository to release Crate artifact to   | String | required |  |
| <a id="deploy_crate-snapshot"></a>snapshot |  Snapshot repository to release Crate artifact to   | String | required |  |
| <a id="deploy_crate-target"></a>target |  assemble_crate target to deploy   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_github"></a>

## deploy_github

<pre>
deploy_github(<a href="#deploy_github-name">name</a>, <a href="#deploy_github-archive">archive</a>, <a href="#deploy_github-draft">draft</a>, <a href="#deploy_github-organisation">organisation</a>, <a href="#deploy_github-release_description">release_description</a>, <a href="#deploy_github-repository">repository</a>, <a href="#deploy_github-title">title</a>,
              <a href="#deploy_github-title_append_version">title_append_version</a>, <a href="#deploy_github-version_file">version_file</a>)
</pre>

Deploy `assemble_versioned` target to GitHub Releases

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_github-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_github-archive"></a>archive |  <code>assemble_versioned</code> label to be deployed.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_github-draft"></a>draft |  Creates an unpublished / draft release when set to True.             Defaults to True.   | Boolean | optional | True |
| <a id="deploy_github-organisation"></a>organisation |  Github organisation to deploy to   | String | required |  |
| <a id="deploy_github-release_description"></a>release_description |  Description of GitHub release   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="deploy_github-repository"></a>repository |  Github repository to deploy to within organisation   | String | required |  |
| <a id="deploy_github-title"></a>title |  Title of GitHub release   | String | optional | "" |
| <a id="deploy_github-title_append_version"></a>title_append_version |  Append version to GitHub release title   | Boolean | optional | False |
| <a id="deploy_github-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_maven"></a>

## deploy_maven

<pre>
deploy_maven(<a href="#deploy_maven-name">name</a>, <a href="#deploy_maven-release">release</a>, <a href="#deploy_maven-snapshot">snapshot</a>, <a href="#deploy_maven-target">target</a>)
</pre>

Deploy `assemble_maven` target into Maven repo

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_maven-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_maven-release"></a>release |  Release repository to release maven artifact to   | String | required |  |
| <a id="deploy_maven-snapshot"></a>snapshot |  Snapshot repository to release maven artifact to   | String | required |  |
| <a id="deploy_maven-target"></a>target |  assemble_maven target to deploy   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_npm"></a>

## deploy_npm

<pre>
deploy_npm(<a href="#deploy_npm-name">name</a>, <a href="#deploy_npm-release">release</a>, <a href="#deploy_npm-snapshot">snapshot</a>, <a href="#deploy_npm-target">target</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_npm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_npm-release"></a>release |  Release repository to deploy npm artifact to   | String | required |  |
| <a id="deploy_npm-snapshot"></a>snapshot |  Snapshot repository to deploy npm artifact to   | String | required |  |
| <a id="deploy_npm-target"></a>target |  <code>assemble_npm</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_packer"></a>

## deploy_packer

<pre>
deploy_packer(<a href="#deploy_packer-name">name</a>, <a href="#deploy_packer-overwrite">overwrite</a>, <a href="#deploy_packer-target">target</a>)
</pre>

Execute Packer to perform deployment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_packer-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_packer-overwrite"></a>overwrite |  Overwrite already-existing image   | Boolean | optional | False |
| <a id="deploy_packer-target"></a>target |  <code>assemble_packer</code> label to be deployed.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#deploy_pip"></a>

## deploy_pip

<pre>
deploy_pip(<a href="#deploy_pip-name">name</a>, <a href="#deploy_pip-release">release</a>, <a href="#deploy_pip-snapshot">snapshot</a>, <a href="#deploy_pip-target">target</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_pip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_pip-release"></a>release |  Remote repository to deploy pip release to   | String | required |  |
| <a id="deploy_pip-snapshot"></a>snapshot |  Remote repository to deploy pip snapshot to   | String | required |  |
| <a id="deploy_pip-target"></a>target |  <code>assemble_pip</code> label to be included in the package   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#deploy_rpm"></a>

## deploy_rpm

<pre>
deploy_rpm(<a href="#deploy_rpm-name">name</a>, <a href="#deploy_rpm-release">release</a>, <a href="#deploy_rpm-snapshot">snapshot</a>, <a href="#deploy_rpm-target">target</a>)
</pre>

Deploy package built with `assemble_rpm` to RPM repository

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="deploy_rpm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="deploy_rpm-release"></a>release |  Remote repository to deploy rpm release to   | String | required |  |
| <a id="deploy_rpm-snapshot"></a>snapshot |  Remote repository to deploy rpm snapshot to   | String | required |  |
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
java_deps(<a href="#java_deps-name">name</a>, <a href="#java_deps-java_deps_root">java_deps_root</a>, <a href="#java_deps-java_deps_root_overrides">java_deps_root_overrides</a>, <a href="#java_deps-maven_name">maven_name</a>, <a href="#java_deps-target">target</a>, <a href="#java_deps-version_file">version_file</a>)
</pre>

Packs Java library alongside with its dependencies into archive

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="java_deps-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="java_deps-java_deps_root"></a>java_deps_root |  Folder inside archive to put JARs into   | String | optional | "" |
| <a id="java_deps-java_deps_root_overrides"></a>java_deps_root_overrides |  JARs with filenames matching the given patterns will be placed into the specified folders inside the archive,             instead of the default folder. Patterns can be either the full name of a JAR, or a prefix followed by a '*'.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="java_deps-maven_name"></a>maven_name |  Name JAR files inside archive based on Maven coordinates   | Boolean | optional | False |
| <a id="java_deps-target"></a>target |  Java target to pack into archive   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="java_deps-version_file"></a>version_file |  File containing version string.             Alternatively, pass --define version=VERSION to Bazel invocation.             Not specifying version at all defaults to '0.0.0'   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#tgz2zip"></a>

## tgz2zip

<pre>
tgz2zip(<a href="#tgz2zip-name">name</a>, <a href="#tgz2zip-output_filename">output_filename</a>, <a href="#tgz2zip-tgz">tgz</a>)
</pre>

Converts .tar.gz into .zip

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tgz2zip-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tgz2zip-output_filename"></a>output_filename |  Resulting filename   | String | required |  |
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


<a id="#MavenDeploymentInfo"></a>

## MavenDeploymentInfo

<pre>
MavenDeploymentInfo(<a href="#MavenDeploymentInfo-jar">jar</a>, <a href="#MavenDeploymentInfo-srcjar">srcjar</a>, <a href="#MavenDeploymentInfo-pom">pom</a>)
</pre>



**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="MavenDeploymentInfo-jar"></a>jar |  JAR file to deploy    |
| <a id="MavenDeploymentInfo-srcjar"></a>srcjar |  JAR file with sources    |
| <a id="MavenDeploymentInfo-pom"></a>pom |  Accompanying pom.xml file    |


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
assemble_azure(<a href="#assemble_azure-name">name</a>, <a href="#assemble_azure-image_name">image_name</a>, <a href="#assemble_azure-resource_group_name">resource_group_name</a>, <a href="#assemble_azure-install">install</a>, <a href="#assemble_azure-image_publisher">image_publisher</a>, <a href="#assemble_azure-image_offer">image_offer</a>,
               <a href="#assemble_azure-image_sku">image_sku</a>, <a href="#assemble_azure-disk_size_gb">disk_size_gb</a>, <a href="#assemble_azure-files">files</a>)
</pre>

Assemble files for Azure deployment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_azure-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_azure-image_name"></a>image_name |  name of deployed image   |  none |
| <a id="assemble_azure-resource_group_name"></a>resource_group_name |  name of the resource group to place image in   |  none |
| <a id="assemble_azure-install"></a>install |  Bazel label for install file   |  none |
| <a id="assemble_azure-image_publisher"></a>image_publisher |  Publisher of the image used as base   |  <code>"Canonical"</code> |
| <a id="assemble_azure-image_offer"></a>image_offer |  Offer of the image used as base   |  <code>"0001-com-ubuntu-server-focal"</code> |
| <a id="assemble_azure-image_sku"></a>image_sku |  SKU of the image used as base   |  <code>"20_04-lts"</code> |
| <a id="assemble_azure-disk_size_gb"></a>disk_size_gb |  Size of the resulting OS disk   |  <code>60</code> |
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
             <a href="#assemble_zip-append_version">append_version</a>, <a href="#assemble_zip-visibility">visibility</a>, <a href="#assemble_zip-tags">tags</a>)
</pre>

Assemble distribution archive (.zip)

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assemble_zip-name"></a>name |  A unique name for this target.   |  none |
| <a id="assemble_zip-output_filename"></a>output_filename |  filename of resulting archive   |  none |
| <a id="assemble_zip-targets"></a>targets |  Bazel labels of archives that go into .tar.gz package   |  <code>[]</code> |
| <a id="assemble_zip-additional_files"></a>additional_files |  mapping between Bazel labels of files that go into archive     and their resulting location in archive   |  <code>{}</code> |
| <a id="assemble_zip-empty_directories"></a>empty_directories |  list of empty directories created at archive installation   |  <code>[]</code> |
| <a id="assemble_zip-permissions"></a>permissions |  mapping between paths and UNIX permissions   |  <code>{}</code> |
| <a id="assemble_zip-append_version"></a>append_version |  append version to root folder inside the archive   |  <code>True</code> |
| <a id="assemble_zip-visibility"></a>visibility |  controls whether the target can be used by other packages   |  <code>["//visibility:private"]</code> |
| <a id="assemble_zip-tags"></a>tags |  <p align="center"> - </p>   |  <code>[]</code> |


