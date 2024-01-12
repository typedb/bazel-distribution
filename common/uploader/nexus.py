import hashlib
import requests

from .uploader import Uploader, DeploymentException

class NexusUploader(Uploader):
    COMMON_OPTS = set()

    def __init__(self, username, password, url):
        self.auth = requests.auth.HTTPBasicAuth(username, password)

        if not url.startswith("http"):
            raise ValueError(
                "Invalid url for repository. Expected http or https. Received:" % url)
        self.repo_url = url.rstrip("/") + "/"

    def _upload_file_impl(self, file, url, use_post):
        if use_post:
            headers = {"Content-Type" : "multipart/form-data"}
            print("Trying: Upload %s to %s using %s"%(file, url, "POST" if use_post else "PUT"))
            return requests.post(url, auth = self.auth, data = open(file, "rb").read() , headers = headers)
        else:
            print("Trying: Upload %s to %s using %s"%(file, url, "POST" if use_post else "PUT"))
            return requests.put(url, auth = self.auth, data = open(file, "rb").read())

    def _upload_string_impl(self, data, url):
        print("Trying: Upload %s to %s using %s"%(data, url, "POST" if use_post else "PUT"))
        return requests.put(url, auth = self.auth, data = data)

    def _upload_file(self, file, url, use_post = False):
        # self._upload_file_impl(file, url, use_post)
        response = self._upload_file_impl(file, url, use_post)
        success = (response.status_code // 100) == 2
        if not success:
            raise DeploymentException("HTTP request for %s failed" % "upload", response) # TODO: Fix type
        else:
            return True

    def _upload_file_and_may_sign(self, file, url, should_sign):
        use_post = False
        stage = "upload"
        response = self._upload_file_impl(file, url, use_post)
        success = True
        success = (response.status_code // 100)== 2
        if success and should_sign:
            stage = "sign"
            response = self._upload_file_impl(self._sign(file), url + ".asc", use_post)
            success = (response.status_code // 100)== 2
        if success:
            stage = "md5"
            md5 = hashlib.md5(open(file, 'rb').read()).hexdigest()
            response = self._upload_string_impl(md5, url + ".md5", use_post)
            success = (response.status_code // 100)== 2
        if success:
            stage = "sha1"
            sha1 = hashlib.sha1(open(file, 'rb').read()).hexdigest()
            response = self._upload_string_impl(sha1, url + ".sha1", use_post)
            success = (response.status_code // 100)== 2

        if not success:
            from .cloudsmith import  DeploymentException
            raise DeploymentException("HTTP request for %s failed" % stage, response) # TODO: Fix type
        else:
            return True
    def _validate_opts(self, opts, accepted_opts):
        unrecognised_fields = [f for f in opts if f not in accepted_opts.union(NexusUploader.COMMON_OPTS)]
        if len(unrecognised_fields) != 0:
            raise ValueError("Unrecognised option: " + str(unrecognised_fields))

    def _sign(self, fn):
        import tempfile
        import subprocess as sp
        # TODO(vmax): current limitation of this functionality
        # is that gpg key should already be present in keyring
        # and should not require passphrase
        asc_file = tempfile.mktemp()
        sp.check_call([
            'gpg',
            '--detach-sign',
            '--armor',
            '--output',
            asc_file,
            fn
        ])
        return asc_file

    #Impl
    def apt(self, deb_file, distro="ignored", opts={}):
        accepted_opts = set()
        self._validate_opts(opts, accepted_opts)
        upload_url = self.repo_url
        success = self._upload_file(deb_file, upload_url, use_post = True)
        return success, self.upload_url

    def artifact(self, artifact_group, version, artifact_path, filename, opts={}):
        accepted_opts = set()
        self._validate_opts(opts, accepted_opts)
        upload_url = "%s/%s/%s/%s" %(self.repo_url.rstrip("/"), artifact_group, version, filename)
        success = self._upload_file(artifact_path, upload_url)
        return success, upload_url

    def helm(self, tar_path, opts={}):
        accepted_opts = set()
        self._validate_opts(opts, accepted_opts)
        upload_url = "%s/api/charts"%(self.repo_url.rstrip("/"))
        success = self._upload_file(tar_path, upload_url, use_post=True)
        return success, upload_url

    def maven(self, group_id, artifact_id, version,
        jar_path, pom_path,
        sources_path=None, javadoc_path=None, tests_path = None,
        should_sign = True,
        opts={}):
        accepted_opts = set()
        self._validate_opts(opts, accepted_opts)
        jar_filename, pom_filename, sources_filename, javadoc_filename, tests_filename = \
            Uploader._maven_names(artifact_id, version, sources_path, javadoc_path, tests_path)
        base_url = "{repo_url}/{coordinates}/{artifact}/{version}/".format(
            repo_url = self.repo_url.rstrip("/"), coordinates=group_id.text.replace('.', '/'), version=version, artifact=artifact_id)
        print(base_url, jar_filename, pom_filename, sources_filename, javadoc_filename, tests_filename)
        jar_url = base_url + jar_filename
        pom_url = base_url + pom_filename
        success = True
        success = success and self._upload_file_and_may_sign(jar_path, jar_url, should_sign)
        success = success and self._upload_file_and_may_sign(pom_path, pom_url, should_sign)
        if javadoc_path is not None:
            javadoc_url = base_url + javadoc_filename
            success = success and self._upload_file_and_may_sign(javadoc_path, javadoc_url, should_sign)
        if sources_path is not None:
            sources_url = base_url + sources_filename
            success = success and self._upload_file_and_may_sign(sources_path, sources_url, should_sign)
        if tests_path is not None:
            tests_url = base_url + tests_filename
            success = success and self._upload_file_and_may_sign(tests_path, tests_url, should_sign)

        return success, pom_url
