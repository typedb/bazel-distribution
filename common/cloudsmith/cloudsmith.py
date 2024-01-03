import os
import re
import requests
import time

class CloudsmithDeploymentException(Exception):
    def __init__(self, msg, response = None):
        self.msg = msg
        self.response = response

    def __str__(self):
        ret = "CloudsmithDeploymentException: %s"%(self.msg)
        if self.response is not None:
            ret += ". HTTP response as [%d]: %s"%(self.response.status_code, self.response.text)
        return ret

class CloudsmithDeployment:
    COMMON_OPTS = ["tags"]

    def __init__(self, username, password, cloudsmith_url):
        self.auth = requests.auth.HTTPBasicAuth(username, password)
        res = re.search(r"cloudsmith:\/\/([^\/]+)/([^\/]+)\/?", cloudsmith_url)
        if res is None:
            raise CloudsmithDeploymentException("Unrecognised cloudsmith_url: %s"%cloudsmith_url)
        self.repo_owner = res.group(1)
        self.repo = res.group(2)

    def _upload_file(self, file, filename=None):
        headers = {}
        url = "https://upload.cloudsmith.io/%s/%s/%s"%(self.repo_owner, self.repo, filename)
        resp = requests.put(url, auth=self.auth, headers=headers, data=open(file, 'rb').read())
        return self._check_status_code("file upload", resp), resp

    def _post_metadata(self, package_type, data):
        headers = {}
        url = "https://api-prd.cloudsmith.io/v1/packages/%s/%s/upload/%s/"%(self.repo_owner, self.repo, package_type)
        post_response = requests.post(url, auth=self.auth, headers=headers, json = data)
        return self._check_status_code("metadata post", post_response), post_response

    def _wait_for_sync(self, slug):
        print("Checking sync status for slug: %s..."%slug)
        url = "https://api.cloudsmith.io/v1/packages/%s/%s/%s/status/"%(self.repo_owner, self.repo, slug)
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

        success = response is not None and self._check_status_code("sync status", response) and response.json()["is_sync_completed"]
        return success, response

    def _check_status_code(self, stage, response):
        if (response.status_code // 100) != 2:
            raise CloudsmithDeploymentException("HTTP request for %s failed"%stage, response)
        else:
            return True

    def _validate_opts(self, opts, accepted_opts):
        unrecognised_fields = [f for f in opts if f not in accepted_opts]
        if len(unrecognised_fields) != 0:
            raise CloudsmithDeploymentException("Unrecognised option: " + str(unrecognised_fields))

    def _get_slug(selfself, metadata_post_response):
        return metadata_post_response.json()["slug_perm"]

    def artifact(self, name, version, artifact_path, opts = {}):
        accepted_opts = {"description", "summary"}
        self._validate_opts(opts, accepted_opts)
        success, slug = False, None
        upload_success, upload_resp = self._upload_file(artifact_path, os.path.basename(artifact_path))
        if upload_success:
            print("File uploaded succeeded. Creating package")
            uploaded_id = upload_resp.json()["identifier"]
            data = {
                "package_file": uploaded_id,
                "name" : name,
                "version" : version
            }
            post_success, post_resp = self._post_metadata("raw", data)
            if post_success:
                print("Metadata post request accepted.")
                slug = self._get_slug(post_resp)
                sync_success, sync_resp = self._wait_for_sync(slug)
                if sync_success:
                    print("Sync completed successfully.")
                    success = True
                else:
                    raise CloudsmithDeploymentException("Syncing failed", sync_resp)

        assert(success) # Should have thrown otherwise
        return success, slug
