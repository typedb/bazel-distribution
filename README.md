<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#assemble_maven"></a>

## assemble_maven

<pre>
assemble_maven(<a href="#assemble_maven-name">name</a>, <a href="#assemble_maven-developers">developers</a>, <a href="#assemble_maven-license">license</a>, <a href="#assemble_maven-package">package</a>, <a href="#assemble_maven-project_description">project_description</a>, <a href="#assemble_maven-project_name">project_name</a>, <a href="#assemble_maven-project_url">project_url</a>, <a href="#assemble_maven-scm_url">scm_url</a>, <a href="#assemble_maven-target">target</a>, <a href="#assemble_maven-version_file">version_file</a>, <a href="#assemble_maven-workspace_refs">workspace_refs</a>)
</pre>

Assemble Java package for subsequent deployment to Maven repo

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_maven-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-developers">
      <td><code>developers</code></td>
      <td>
        <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> List of strings</a>; optional
        <p>
          Project developers to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-license">
      <td><code>license</code></td>
      <td>
        String; optional
        <p>
          Project license to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-package">
      <td><code>package</code></td>
      <td>
        String; optional
        <p>
          Bazel package of this target. Must match one defined in `_maven_packages`
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-project_description">
      <td><code>project_description</code></td>
      <td>
        String; optional
        <p>
          Project description to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-project_name">
      <td><code>project_name</code></td>
      <td>
        String; optional
        <p>
          Project name to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-project_url">
      <td><code>project_url</code></td>
      <td>
        String; optional
        <p>
          Project URL to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-scm_url">
      <td><code>scm_url</code></td>
      <td>
        String; optional
        <p>
          Project source control URL to fill into pom.xml
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Java target for subsequent deployment
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
    <tr id="assemble_maven-workspace_refs">
      <td><code>workspace_refs</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          JSON file describing dependencies to other Bazel workspaces
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_npm"></a>

## assemble_npm

<pre>
assemble_npm(<a href="#assemble_npm-name">name</a>, <a href="#assemble_npm-target">target</a>, <a href="#assemble_npm-version_file">version_file</a>)
</pre>

Assemble `npm_package` target for further deployment

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_npm-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_npm-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          `npm_library` label to be included in the package
        </p>
      </td>
    </tr>
    <tr id="assemble_npm-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_pip"></a>

## assemble_pip

<pre>
assemble_pip(<a href="#assemble_pip-name">name</a>, <a href="#assemble_pip-author">author</a>, <a href="#assemble_pip-author_email">author_email</a>, <a href="#assemble_pip-classifiers">classifiers</a>, <a href="#assemble_pip-description">description</a>, <a href="#assemble_pip-install_requires">install_requires</a>, <a href="#assemble_pip-keywords">keywords</a>, <a href="#assemble_pip-license">license</a>, <a href="#assemble_pip-long_description_file">long_description_file</a>, <a href="#assemble_pip-package_name">package_name</a>, <a href="#assemble_pip-target">target</a>, <a href="#assemble_pip-url">url</a>, <a href="#assemble_pip-version_file">version_file</a>)
</pre>



### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_pip-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-author">
      <td><code>author</code></td>
      <td>
        String; required
        <p>
          Details about the author
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-author_email">
      <td><code>author_email</code></td>
      <td>
        String; required
        <p>
          The email for the author
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-classifiers">
      <td><code>classifiers</code></td>
      <td>
        List of strings; required
        <p>
          A list of strings, containing Python package classifiers
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-description">
      <td><code>description</code></td>
      <td>
        String; required
        <p>
          A string with the short description of the package
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-install_requires">
      <td><code>install_requires</code></td>
      <td>
        List of strings; required
        <p>
          A list of strings which are names of required packages for this one
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-keywords">
      <td><code>keywords</code></td>
      <td>
        List of strings; required
        <p>
          A list of strings, containing keywords
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-license">
      <td><code>license</code></td>
      <td>
        String; required
        <p>
          The type of license to use
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-long_description_file">
      <td><code>long_description_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          A label with the long description of the package. Usually a README or README.rst file
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-package_name">
      <td><code>package_name</code></td>
      <td>
        String; required
        <p>
          A string with Python pip package name
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          `py_library` label to be included in the package
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-url">
      <td><code>url</code></td>
      <td>
        String; required
        <p>
          A homepage for the project
        </p>
      </td>
    </tr>
    <tr id="assemble_pip-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_versioned"></a>

## assemble_versioned

<pre>
assemble_versioned(<a href="#assemble_versioned-name">name</a>, <a href="#assemble_versioned-targets">targets</a>, <a href="#assemble_versioned-version_file">version_file</a>)
</pre>

Version multiple archives for subsequent simultaneous deployment

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_versioned-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_versioned-targets">
      <td><code>targets</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a>; optional
        <p>
          Archives to version and put into output archive
        </p>
      </td>
    </tr>
    <tr id="assemble_versioned-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          File containing version string
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#checksum"></a>

## checksum

<pre>
checksum(<a href="#checksum-name">name</a>, <a href="#checksum-archive">archive</a>)
</pre>

Computes SHA256 checksum of file

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="checksum-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="checksum-archive">
      <td><code>archive</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Archive to compute checksum of
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_apt"></a>

## deploy_apt

<pre>
deploy_apt(<a href="#deploy_apt-name">name</a>, <a href="#deploy_apt-deployment_properties">deployment_properties</a>, <a href="#deploy_apt-target">target</a>)
</pre>

Deploy package built with `assemble_apt` to APT repository

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_apt-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_apt-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Properties file containing repo.apt.(snapshot|release) key
        </p>
      </td>
    </tr>
    <tr id="deploy_apt-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          assemble_apt label to deploy
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_brew"></a>

## deploy_brew

<pre>
deploy_brew(<a href="#deploy_brew-name">name</a>, <a href="#deploy_brew-checksum">checksum</a>, <a href="#deploy_brew-deployment_properties">deployment_properties</a>, <a href="#deploy_brew-formula">formula</a>, <a href="#deploy_brew-type">type</a>, <a href="#deploy_brew-version_file">version_file</a>)
</pre>

Deploy Homebrew (Caskroom) formula to Homebrew tap

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_brew-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_brew-checksum">
      <td><code>checksum</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          Checksum of deployed artifact
        </p>
      </td>
    </tr>
    <tr id="deploy_brew-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Properties file containing repo.brew.(snapshot|release) key
        </p>
      </td>
    </tr>
    <tr id="deploy_brew-formula">
      <td><code>formula</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          The brew formula definition
        </p>
      </td>
    </tr>
    <tr id="deploy_brew-type">
      <td><code>type</code></td>
      <td>
        String; optional
        <p>
          Type of deployment (Homebrew/Caskroom).
            Cask is generally used for graphic applications
        </p>
      </td>
    </tr>
    <tr id="deploy_brew-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_github"></a>

## deploy_github

<pre>
deploy_github(<a href="#deploy_github-name">name</a>, <a href="#deploy_github-archive">archive</a>, <a href="#deploy_github-deployment_properties">deployment_properties</a>, <a href="#deploy_github-release_description">release_description</a>, <a href="#deploy_github-title">title</a>, <a href="#deploy_github-title_append_version">title_append_version</a>, <a href="#deploy_github-version_file">version_file</a>)
</pre>

Deploy `assemble_versioned` target to GitHub Releases

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_github-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_github-archive">
      <td><code>archive</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          `assemble_versioned` label to be deployed.
        </p>
      </td>
    </tr>
    <tr id="deploy_github-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          File containing `repo.github.organisation` and `repo.github.repository` keys
        </p>
      </td>
    </tr>
    <tr id="deploy_github-release_description">
      <td><code>release_description</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          Description of GitHub release
        </p>
      </td>
    </tr>
    <tr id="deploy_github-title">
      <td><code>title</code></td>
      <td>
        String; optional
        <p>
          Title of GitHub release
        </p>
      </td>
    </tr>
    <tr id="deploy_github-title_append_version">
      <td><code>title_append_version</code></td>
      <td>
        Boolean; optional
        <p>
          Append version to GitHub release title
        </p>
      </td>
    </tr>
    <tr id="deploy_github-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_maven"></a>

## deploy_maven

<pre>
deploy_maven(<a href="#deploy_maven-name">name</a>, <a href="#deploy_maven-deployment_properties">deployment_properties</a>, <a href="#deploy_maven-target">target</a>)
</pre>

Deploy `assemble_maven` target into Maven repo

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_maven-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_maven-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Properties file containing repo.maven.(snapshot|release) key
        </p>
      </td>
    </tr>
    <tr id="deploy_maven-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          assemble_maven target to deploy
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_npm"></a>

## deploy_npm

<pre>
deploy_npm(<a href="#deploy_npm-name">name</a>, <a href="#deploy_npm-deployment_properties">deployment_properties</a>, <a href="#deploy_npm-target">target</a>)
</pre>



### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_npm-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_npm-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          File containing Node repository url by `repo.npm` key
        </p>
      </td>
    </tr>
    <tr id="deploy_npm-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          `assemble_npm` label to be included in the package
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_packer"></a>

## deploy_packer

<pre>
deploy_packer(<a href="#deploy_packer-name">name</a>, <a href="#deploy_packer-target">target</a>)
</pre>

Execute Packer to perform deployment

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_packer-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_packer-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          `assemble_packer` label to be deployed.
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_pip"></a>

## deploy_pip

<pre>
deploy_pip(<a href="#deploy_pip-name">name</a>, <a href="#deploy_pip-deployment_properties">deployment_properties</a>, <a href="#deploy_pip-target">target</a>)
</pre>



### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_pip-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_pip-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          File containing Python pip repository url by `repo.pypi` key
        </p>
      </td>
    </tr>
    <tr id="deploy_pip-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          `assemble_pip` label to be included in the package
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#deploy_rpm"></a>

## deploy_rpm

<pre>
deploy_rpm(<a href="#deploy_rpm-name">name</a>, <a href="#deploy_rpm-deployment_properties">deployment_properties</a>, <a href="#deploy_rpm-target">target</a>)
</pre>

Deploy package built with `assemble_rpm` to RPM repository

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="deploy_rpm-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="deploy_rpm-deployment_properties">
      <td><code>deployment_properties</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Properties file containing repo.rpm.(snapshot|release) key
        </p>
      </td>
    </tr>
    <tr id="deploy_rpm-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          `assemble_rpm` target to deploy
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#generate_json_config"></a>

## generate_json_config

<pre>
generate_json_config(<a href="#generate_json_config-name">name</a>, <a href="#generate_json_config-substitutions">substitutions</a>, <a href="#generate_json_config-template">template</a>)
</pre>

Fills in JSON template with provided values

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="generate_json_config-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="generate_json_config-substitutions">
      <td><code>substitutions</code></td>
      <td>
        <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a>; optional
        <p>
          Values to fill in
        </p>
      </td>
    </tr>
    <tr id="generate_json_config-template">
      <td><code>template</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          JSON template to fill in values
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#java_deps"></a>

## java_deps

<pre>
java_deps(<a href="#java_deps-name">name</a>, <a href="#java_deps-java_deps_root">java_deps_root</a>, <a href="#java_deps-maven_name">maven_name</a>, <a href="#java_deps-target">target</a>, <a href="#java_deps-version_file">version_file</a>)
</pre>

Packs Java library alongside with its dependencies into archive

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="java_deps-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="java_deps-java_deps_root">
      <td><code>java_deps_root</code></td>
      <td>
        String; optional
        <p>
          Folder inside archive to put JARs into
        </p>
      </td>
    </tr>
    <tr id="java_deps-maven_name">
      <td><code>maven_name</code></td>
      <td>
        Boolean; optional
        <p>
          Name JAR files inside archive based on Maven coordinates
        </p>
      </td>
    </tr>
    <tr id="java_deps-target">
      <td><code>target</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Java target to pack into archive
        </p>
      </td>
    </tr>
    <tr id="java_deps-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
        <p>
          File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#pkg_deb"></a>

## pkg_deb

<pre>
pkg_deb(<a href="#pkg_deb-name">name</a>, <a href="#pkg_deb-architecture">architecture</a>, <a href="#pkg_deb-built_using">built_using</a>, <a href="#pkg_deb-built_using_file">built_using_file</a>, <a href="#pkg_deb-conffiles">conffiles</a>, <a href="#pkg_deb-conffiles_file">conffiles_file</a>, <a href="#pkg_deb-config">config</a>, <a href="#pkg_deb-conflicts">conflicts</a>, <a href="#pkg_deb-data">data</a>, <a href="#pkg_deb-depends">depends</a>, <a href="#pkg_deb-depends_file">depends_file</a>, <a href="#pkg_deb-description">description</a>, <a href="#pkg_deb-description_file">description_file</a>, <a href="#pkg_deb-distribution">distribution</a>, <a href="#pkg_deb-enhances">enhances</a>, <a href="#pkg_deb-homepage">homepage</a>, <a href="#pkg_deb-maintainer">maintainer</a>, <a href="#pkg_deb-make_deb">make_deb</a>, <a href="#pkg_deb-package">package</a>, <a href="#pkg_deb-postinst">postinst</a>, <a href="#pkg_deb-postrm">postrm</a>, <a href="#pkg_deb-predepends">predepends</a>, <a href="#pkg_deb-preinst">preinst</a>, <a href="#pkg_deb-prerm">prerm</a>, <a href="#pkg_deb-priority">priority</a>, <a href="#pkg_deb-recommends">recommends</a>, <a href="#pkg_deb-section">section</a>, <a href="#pkg_deb-suggests">suggests</a>, <a href="#pkg_deb-templates">templates</a>, <a href="#pkg_deb-urgency">urgency</a>, <a href="#pkg_deb-version">version</a>, <a href="#pkg_deb-version_file">version_file</a>)
</pre>



### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="pkg_deb-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="pkg_deb-architecture">
      <td><code>architecture</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-built_using">
      <td><code>built_using</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-built_using_file">
      <td><code>built_using_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-conffiles">
      <td><code>conffiles</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-conffiles_file">
      <td><code>conffiles_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-config">
      <td><code>config</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-conflicts">
      <td><code>conflicts</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-data">
      <td><code>data</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
      </td>
    </tr>
    <tr id="pkg_deb-depends">
      <td><code>depends</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-depends_file">
      <td><code>depends_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-description">
      <td><code>description</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-description_file">
      <td><code>description_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-distribution">
      <td><code>distribution</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-enhances">
      <td><code>enhances</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-homepage">
      <td><code>homepage</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-maintainer">
      <td><code>maintainer</code></td>
      <td>
        String; required
      </td>
    </tr>
    <tr id="pkg_deb-make_deb">
      <td><code>make_deb</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-package">
      <td><code>package</code></td>
      <td>
        String; required
      </td>
    </tr>
    <tr id="pkg_deb-postinst">
      <td><code>postinst</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-postrm">
      <td><code>postrm</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-predepends">
      <td><code>predepends</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-preinst">
      <td><code>preinst</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-prerm">
      <td><code>prerm</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-priority">
      <td><code>priority</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-recommends">
      <td><code>recommends</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-section">
      <td><code>section</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-suggests">
      <td><code>suggests</code></td>
      <td>
        List of strings; optional
      </td>
    </tr>
    <tr id="pkg_deb-templates">
      <td><code>templates</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
    <tr id="pkg_deb-urgency">
      <td><code>urgency</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-version">
      <td><code>version</code></td>
      <td>
        String; optional
      </td>
    </tr>
    <tr id="pkg_deb-version_file">
      <td><code>version_file</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; optional
      </td>
    </tr>
  </tbody>
</table>


<a name="#tgz2zip"></a>

## tgz2zip

<pre>
tgz2zip(<a href="#tgz2zip-name">name</a>, <a href="#tgz2zip-output_filename">output_filename</a>, <a href="#tgz2zip-prefix">prefix</a>, <a href="#tgz2zip-tgz">tgz</a>)
</pre>

Converts .tar.gz into .zip

### Attributes

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="tgz2zip-name">
      <td><code>name</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#name">Name</a>; required
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="tgz2zip-output_filename">
      <td><code>output_filename</code></td>
      <td>
        String; required
        <p>
          Resulting filename
        </p>
      </td>
    </tr>
    <tr id="tgz2zip-prefix">
      <td><code>prefix</code></td>
      <td>
        String; optional
        <p>
          Prefix of files in archive
        </p>
      </td>
    </tr>
    <tr id="tgz2zip-tgz">
      <td><code>tgz</code></td>
      <td>
        <a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; required
        <p>
          Input .tar.gz archive
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#JarToMavenCoordinatesMapping"></a>

## JarToMavenCoordinatesMapping

<pre>
JarToMavenCoordinatesMapping(<a href="#JarToMavenCoordinatesMapping-filename">filename</a>, <a href="#JarToMavenCoordinatesMapping-maven_coordinates">maven_coordinates</a>)
</pre>



### Fields

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="JarToMavenCoordinatesMapping-filename">
      <td><code>filename</code></td>
      <td>
        <p>jar filename</p>
      </td>
    </tr>
    <tr id="JarToMavenCoordinatesMapping-maven_coordinates">
      <td><code>maven_coordinates</code></td>
      <td>
        <p>Maven coordinates of the jar</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#JavaLibInfo"></a>

## JavaLibInfo

<pre>
JavaLibInfo(<a href="#JavaLibInfo-target_coordinates">target_coordinates</a>, <a href="#JavaLibInfo-target_deps_coordinates">target_deps_coordinates</a>)
</pre>



### Fields

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="JavaLibInfo-target_coordinates">
      <td><code>target_coordinates</code></td>
      <td>
        <p>The Maven coordinates for the artifacts that are exported by this target: i.e. the target
        itself and its transitively exported targets.</p>
      </td>
    </tr>
    <tr id="JavaLibInfo-target_deps_coordinates">
      <td><code>target_deps_coordinates</code></td>
      <td>
        <p>The Maven coordinates of the direct dependencies, and the transitively exported targets, of
        this target.</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#MavenDeploymentInfo"></a>

## MavenDeploymentInfo

<pre>
MavenDeploymentInfo(<a href="#MavenDeploymentInfo-jar">jar</a>, <a href="#MavenDeploymentInfo-srcjar">srcjar</a>, <a href="#MavenDeploymentInfo-pom">pom</a>)
</pre>



### Fields

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="MavenDeploymentInfo-jar">
      <td><code>jar</code></td>
      <td>
        <p>JAR file to deploy</p>
      </td>
    </tr>
    <tr id="MavenDeploymentInfo-srcjar">
      <td><code>srcjar</code></td>
      <td>
        <p>JAR file with sources</p>
      </td>
    </tr>
    <tr id="MavenDeploymentInfo-pom">
      <td><code>pom</code></td>
      <td>
        <p>Accompanying pom.xml file</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#MavenPomInfo"></a>

## MavenPomInfo

<pre>
MavenPomInfo(<a href="#MavenPomInfo-maven_pom_deps">maven_pom_deps</a>)
</pre>



### Fields

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="MavenPomInfo-maven_pom_deps">
      <td><code>maven_pom_deps</code></td>
      <td>
        <p>Maven coordinates for dependencies, transitively collected</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#TransitiveJarToMavenCoordinatesMapping"></a>

## TransitiveJarToMavenCoordinatesMapping

<pre>
TransitiveJarToMavenCoordinatesMapping(<a href="#TransitiveJarToMavenCoordinatesMapping-mapping">mapping</a>)
</pre>



### Fields

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="TransitiveJarToMavenCoordinatesMapping-mapping">
      <td><code>mapping</code></td>
      <td>
        <p>maps jar filename to coordinates</p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_apt"></a>

## assemble_apt

<pre>
assemble_apt(<a href="#assemble_apt-name">name</a>, <a href="#assemble_apt-package_name">package_name</a>, <a href="#assemble_apt-maintainer">maintainer</a>, <a href="#assemble_apt-description">description</a>, <a href="#assemble_apt-version_file">version_file</a>, <a href="#assemble_apt-installation_dir">installation_dir</a>, <a href="#assemble_apt-workspace_refs">workspace_refs</a>, <a href="#assemble_apt-archives">archives</a>, <a href="#assemble_apt-empty_dirs">empty_dirs</a>, <a href="#assemble_apt-files">files</a>, <a href="#assemble_apt-depends">depends</a>, <a href="#assemble_apt-symlinks">symlinks</a>, <a href="#assemble_apt-permissions">permissions</a>)
</pre>

Assemble package for installation with APT

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_apt-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-package_name">
      <td><code>package_name</code></td>
      <td>
        required.
        <p>
          Package name for built .deb package
    https://www.debian.org/doc/debian-policy/ch-controlfields#package
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-maintainer">
      <td><code>maintainer</code></td>
      <td>
        required.
        <p>
          The package maintainer's name and email address.
    The name must come first, then the email address
    inside angle brackets <> (in RFC822 format)
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-description">
      <td><code>description</code></td>
      <td>
        required.
        <p>
          description of the built package
    https://www.debian.org/doc/debian-policy/ch-controlfields#description
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-version_file">
      <td><code>version_file</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          File containing version number of a package.
    Alternatively, pass --define version=VERSION to Bazel invocation.
    Specifying commit SHA will result in prepending '0.0.0' to it to comply with Debian rules.
    Not specifying version at all defaults to '0.0.0'
    https://www.debian.org/doc/debian-policy/ch-controlfields#version
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-installation_dir">
      <td><code>installation_dir</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          directory into which .deb package is unpacked at installation
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-workspace_refs">
      <td><code>workspace_refs</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          JSON file with other Bazel workspace references
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-archives">
      <td><code>archives</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          Bazel labels of archives that go into .deb package
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-empty_dirs">
      <td><code>empty_dirs</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          list of empty directories created at package installation
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-files">
      <td><code>files</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between Bazel labels of archives that go into .deb package
    and their resulting location on .deb package installation
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-depends">
      <td><code>depends</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          list of Debian packages this package depends on
    https://www.debian.org/doc/debian-policy/ch-relationships.htm
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-symlinks">
      <td><code>symlinks</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between source and target of symbolic links
    created at installation
        </p>
      </td>
    </tr>
    <tr id="assemble_apt-permissions">
      <td><code>permissions</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between paths and UNIX permissions
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_aws"></a>

## assemble_aws

<pre>
assemble_aws(<a href="#assemble_aws-name">name</a>, <a href="#assemble_aws-ami_name">ami_name</a>, <a href="#assemble_aws-install">install</a>, <a href="#assemble_aws-region">region</a>, <a href="#assemble_aws-files">files</a>)
</pre>

Assemble files for AWS deployment

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_aws-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_aws-ami_name">
      <td><code>ami_name</code></td>
      <td>
        required.
        <p>
          AMI name of deployed image
        </p>
      </td>
    </tr>
    <tr id="assemble_aws-install">
      <td><code>install</code></td>
      <td>
        required.
        <p>
          Bazel label for install file
        </p>
      </td>
    </tr>
    <tr id="assemble_aws-region">
      <td><code>region</code></td>
      <td>
        required.
        <p>
          AWS region to deploy image to
        </p>
      </td>
    </tr>
    <tr id="assemble_aws-files">
      <td><code>files</code></td>
      <td>
        required.
        <p>
          Files to include into AWS deployment
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_gcp"></a>

## assemble_gcp

<pre>
assemble_gcp(<a href="#assemble_gcp-name">name</a>, <a href="#assemble_gcp-project_id">project_id</a>, <a href="#assemble_gcp-install">install</a>, <a href="#assemble_gcp-zone">zone</a>, <a href="#assemble_gcp-image_name">image_name</a>, <a href="#assemble_gcp-image_licenses">image_licenses</a>, <a href="#assemble_gcp-files">files</a>)
</pre>

Assemble files for GCP deployment

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_gcp-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-project_id">
      <td><code>project_id</code></td>
      <td>
        required.
        <p>
          Google project id
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-install">
      <td><code>install</code></td>
      <td>
        required.
        <p>
          Bazel label for install file
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-zone">
      <td><code>zone</code></td>
      <td>
        required.
        <p>
          GCP zone to deploy image to
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-image_name">
      <td><code>image_name</code></td>
      <td>
        required.
        <p>
          name of deployed image
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-image_licenses">
      <td><code>image_licenses</code></td>
      <td>
        required.
        <p>
          licenses to attach to deployed image
        </p>
      </td>
    </tr>
    <tr id="assemble_gcp-files">
      <td><code>files</code></td>
      <td>
        required.
        <p>
          Files to include into GCP deployment
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_packer"></a>

## assemble_packer

<pre>
assemble_packer(<a href="#assemble_packer-name">name</a>, <a href="#assemble_packer-config">config</a>, <a href="#assemble_packer-files">files</a>)
</pre>

Assemble files for HashiCorp Packer deployment

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_packer-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_packer-config">
      <td><code>config</code></td>
      <td>
        required.
        <p>
          Packer JSON config
        </p>
      </td>
    </tr>
    <tr id="assemble_packer-files">
      <td><code>files</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          Files to include into deployment
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_rpm"></a>

## assemble_rpm

<pre>
assemble_rpm(<a href="#assemble_rpm-name">name</a>, <a href="#assemble_rpm-package_name">package_name</a>, <a href="#assemble_rpm-spec_file">spec_file</a>, <a href="#assemble_rpm-version_file">version_file</a>, <a href="#assemble_rpm-workspace_refs">workspace_refs</a>, <a href="#assemble_rpm-installation_dir">installation_dir</a>, <a href="#assemble_rpm-archives">archives</a>, <a href="#assemble_rpm-empty_dirs">empty_dirs</a>, <a href="#assemble_rpm-files">files</a>, <a href="#assemble_rpm-permissions">permissions</a>, <a href="#assemble_rpm-symlinks">symlinks</a>)
</pre>

Assemble package for installation with RPM

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_rpm-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-package_name">
      <td><code>package_name</code></td>
      <td>
        required.
        <p>
          Package name for built .deb package
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-spec_file">
      <td><code>spec_file</code></td>
      <td>
        required.
        <p>
          The RPM spec file to use
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-version_file">
      <td><code>version_file</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          File containing version number of a package.
    Alternatively, pass --define version=VERSION to Bazel invocation.
    Not specifying version defaults to '0.0.0'
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-workspace_refs">
      <td><code>workspace_refs</code></td>
      <td>
        optional. default is <code>None</code>
      </td>
    </tr>
    <tr id="assemble_rpm-installation_dir">
      <td><code>installation_dir</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          directory into which .rpm package is unpacked at installation
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-archives">
      <td><code>archives</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          Bazel labels of archives that go into .rpm package
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-empty_dirs">
      <td><code>empty_dirs</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          list of empty directories created at package installation
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-files">
      <td><code>files</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between Bazel labels of archives that go into .rpm package
    and their resulting location on .rpm package installation
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-permissions">
      <td><code>permissions</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between paths and UNIX permissions
        </p>
      </td>
    </tr>
    <tr id="assemble_rpm-symlinks">
      <td><code>symlinks</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between source and target of symbolic links
            created at installation
        </p>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_targz"></a>

## assemble_targz

<pre>
assemble_targz(<a href="#assemble_targz-name">name</a>, <a href="#assemble_targz-output_filename">output_filename</a>, <a href="#assemble_targz-targets">targets</a>, <a href="#assemble_targz-additional_files">additional_files</a>, <a href="#assemble_targz-empty_directories">empty_directories</a>, <a href="#assemble_targz-permissions">permissions</a>, <a href="#assemble_targz-visibility">visibility</a>, <a href="#assemble_targz-tags">tags</a>)
</pre>

Assemble distribution archive (.tar.gz)

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_targz-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-output_filename">
      <td><code>output_filename</code></td>
      <td>
        optional. default is <code>None</code>
        <p>
          filename of resulting archive
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-targets">
      <td><code>targets</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          Bazel labels of archives that go into .tar.gz package
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-additional_files">
      <td><code>additional_files</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between Bazel labels of files that go into archive
    and their resulting location in archive
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-empty_directories">
      <td><code>empty_directories</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          list of empty directories created at archive installation
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-permissions">
      <td><code>permissions</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between paths and UNIX permissions
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-visibility">
      <td><code>visibility</code></td>
      <td>
        optional. default is <code>["//visibility:private"]</code>
        <p>
          controls whether the target can be used by other packages
        </p>
      </td>
    </tr>
    <tr id="assemble_targz-tags">
      <td><code>tags</code></td>
      <td>
        optional. default is <code>[]</code>
      </td>
    </tr>
  </tbody>
</table>


<a name="#assemble_zip"></a>

## assemble_zip

<pre>
assemble_zip(<a href="#assemble_zip-name">name</a>, <a href="#assemble_zip-output_filename">output_filename</a>, <a href="#assemble_zip-targets">targets</a>, <a href="#assemble_zip-additional_files">additional_files</a>, <a href="#assemble_zip-empty_directories">empty_directories</a>, <a href="#assemble_zip-permissions">permissions</a>, <a href="#assemble_zip-visibility">visibility</a>)
</pre>

Assemble distribution archive (.zip)

### Parameters

<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="assemble_zip-name">
      <td><code>name</code></td>
      <td>
        required.
        <p>
          A unique name for this target.
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-output_filename">
      <td><code>output_filename</code></td>
      <td>
        required.
        <p>
          filename of resulting archive
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-targets">
      <td><code>targets</code></td>
      <td>
        required.
        <p>
          Bazel labels of archives that go into .tar.gz package
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-additional_files">
      <td><code>additional_files</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between Bazel labels of files that go into archive
    and their resulting location in archive
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-empty_directories">
      <td><code>empty_directories</code></td>
      <td>
        optional. default is <code>[]</code>
        <p>
          list of empty directories created at archive installation
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-permissions">
      <td><code>permissions</code></td>
      <td>
        optional. default is <code>{}</code>
        <p>
          mapping between paths and UNIX permissions
        </p>
      </td>
    </tr>
    <tr id="assemble_zip-visibility">
      <td><code>visibility</code></td>
      <td>
        optional. default is <code>["//visibility:private"]</code>
        <p>
          controls whether the target can be used by other packages
        </p>
      </td>
    </tr>
  </tbody>
</table>


