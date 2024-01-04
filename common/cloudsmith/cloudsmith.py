import os
import re
import requests
import time


class CloudsmithDeploymentException(Exception):
    def __init__(self, msg, response=None):
        self.msg = msg
        self.response = response

    def __str__(self):
        ret = "CloudsmithDeploymentException: %s" % (self.msg)
        if self.response is not None:
            ret += ". HTTP response was [%d]: %s" % (self.response.status_code, self.response.text)
        return ret


class CloudsmithDeployment:
    COMMON_OPTS = {"tags"}

    # Interface with the cloudsmith api
    def __init__(self, username, password, cloudsmith_url):
        self.auth = requests.auth.HTTPBasicAuth(username, password)
        res = re.search(r"cloudsmith:\/\/([^\/]+)/([^\/]+)\/?", cloudsmith_url)
        if res is None:
            raise CloudsmithDeploymentException(
                "Invalid cloudsmith_url. Expected cloudsmith://<owner>/<repo> but was: %s" % cloudsmith_url)
        self.repo_owner = res.group(1)
        self.repo = res.group(2)

    def _upload_file_impl(self, file, filename):
        headers = {}
        url = "https://upload.cloudsmith.io/%s/%s/%s" % (self.repo_owner, self.repo, filename)
        return requests.put(url, auth=self.auth, headers=headers, data=open(file, 'rb').read())

    def _post_metadata_impl(self, package_type, data):
        headers = {}
        url = "https://api-prd.cloudsmith.io/v1/packages/%s/%s/upload/%s/" % (self.repo_owner, self.repo, package_type)
        return requests.post(url, auth=self.auth, headers=headers, json=data)

    def _wait_for_sync_impl(self, slug):
        url = "https://api.cloudsmith.io/v1/packages/%s/%s/%s/status/" % (self.repo_owner, self.repo, slug)
        syncing = True
        response = None
        ctr = 0
        while syncing:
            if ctr >= 10:
                raise CloudsmithDeploymentException("Sync still in progress after 10 attempts. Failing...")
            response = requests.get(url, auth=self.auth)
            self._check_status_code("sync status", response)
            json = response.json()
            syncing = json["is_sync_in_progress"] or not (json["is_sync_completed"] or json["is_sync_failed"])
            ctr += 1
            time.sleep(2)
        return response

    def _upload_file(self, file, filename):
        print("Uploading file: %s" % filename)
        resp = self._upload_file_impl(file, filename)
        self._check_status_code("file upload", resp)
        print("- Success!")
        return resp.json()["identifier"]

    def _post_metadata(self, package_type, data):
        print("Creating package: %s" % package_type)
        resp = self._post_metadata_impl(package_type, data)
        self._check_status_code("metadata post", resp)
        print("- Success!")
        return self._get_slug(resp)

    def _wait_for_sync(self, slug):
        print("Checking sync status for slug: %s" % slug)
        resp = self._wait_for_sync_impl(slug)
        self._check_status_code("sync status", resp)
        success = resp.json()["is_sync_completed"]
        if success:
            print("- Success!")
        else:
            raise CloudsmithDeploymentException("Syncing failed", resp)
        return success

    def _check_status_code(self, stage, response):
        if (response.status_code // 100) != 2:
            raise CloudsmithDeploymentException("HTTP request for %s failed" % stage, response)
        else:
            return True

    def _validate_opts(self, opts, accepted_opts):
        unrecognised_fields = [f for f in opts if f not in accepted_opts.union(CloudsmithDeployment.COMMON_OPTS)]
        if len(unrecognised_fields) != 0:
            raise CloudsmithDeploymentException("Unrecognised option: " + str(unrecognised_fields))

    def _get_slug(self, metadata_post_response):
        return metadata_post_response.json()["slug_perm"]

    def _pick_filename(self, path, preferred_filename):
        return preferred_filename if preferred_filename else os.path.basename(path)

    # Specific
    def apt(self, deb_file, distro="any-distro/any-version", opts={}):
        accepted_opts = {}
        self._validate_opts(opts, accepted_opts)
        uploaded_id = self._upload_file(deb_file, os.path.basename(deb_file))
        data = {
            "package_file": uploaded_id,
            "distribution": distro,
        }
        slug = self._post_metadata("deb", data)
        sync_success = self._wait_for_sync(slug)
        assert (sync_success)
        return sync_success, slug

    def artifact(self, name, version, artifact_path, filename, opts={}):
        accepted_opts = {"description", "summary"}
        self._validate_opts(opts, accepted_opts)
        uploaded_id = self._upload_file(artifact_path, filename)
        data = {
            "package_file": uploaded_id,
            "name": name,
            "version": version
        }
        slug = self._post_metadata("raw", data)
        sync_success = self._wait_for_sync(slug)
        assert (sync_success)
        return sync_success, slug

    def helm(self, tar_path, opts={}):
        accepted_opts = {}
        self._validate_opts(opts, accepted_opts)
        uploaded_id = self._upload_file(tar_path, os.path.basename(tar_path))
        data = {
            "package_file": uploaded_id,
        }
        slug = self._post_metadata("helm", data)
        sync_success = self._wait_for_sync(slug)
        assert (sync_success)
        return sync_success, slug

    def maven(self, group_id, artifact_id,
              jar_path, pom_path, jar_filename=None, pom_filename=None,
              sources_path=None, javadoc_path=None, tests_path=None,
              sources_filename=None, javadoc_filename=None, tests_filename=None,
              opts={}):
        accepted_opts = {}
        self._validate_opts(opts, accepted_opts)
        jar_id = self._upload_file(jar_path, self._pick_filename(jar_path, jar_filename))
        pom_id = self._upload_file(pom_path, self._pick_filename(pom_path, pom_filename))
        data = {
            "group_id": group_id,
            "artifact_id": artifact_id,
            "package_file": jar_id,
            "pom_file": pom_id
        }
        if sources_path is not None:
            data["sources_file"] = self._upload_file(sources_path, self._pick_filename(sources_path, sources_filename))
        if javadoc_path is not None:
            data["javadoc_file"] = self._upload_file(javadoc_path, self._pick_filename(javadoc_path, javadoc_filename))
        if tests_path is not None:
            data["tests_file"] = self._upload_file(tests_path, self._pick_filename(tests_path, tests_filename))

        slug = self._post_metadata("maven", data)
        sync_success = self._wait_for_sync(slug)
        assert (sync_success)
        return sync_success, slug
