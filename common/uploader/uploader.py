import os
from abc import ABC,abstractmethod

class DeploymentException(Exception):
    def __init__(self, msg, response=None):
        self.msg = msg
        self.response = response

    def __str__(self):
        ret = "DeploymentException: %s" % (self.msg)
        if self.response is not None:
            ret += ". HTTP response was [%d]: %s" % (self.response.status_code, self.response.text)
        return ret

class Uploader(ABC):
    @staticmethod
    def create(username, password, repo_url):
        if repo_url.startswith("cloudsmith"):
            from .cloudsmith import CloudsmithUploader
            return CloudsmithUploader(username, password, repo_url)
        elif repo_url.startswith("http"):
            from .nexus import NexusUploader
            return NexusUploader(username, password, repo_url)
        else:
            raise ValueError("Unrecognised url: ", repo_url)

    @staticmethod
    def _maven_names(artifact_id, version, sources_path, javadoc_path, tests_path):
        filename_base = '{artifact}-{version}'.format(artifact=artifact_id, version=version)
        jar_filename = filename_base + ".jar"
        pom_filename = filename_base + ".pom"
        sources_filename = filename_base + "-sources.jar" if sources_path and os.path.exists(sources_path) else None
        javadoc_filename = filename_base + "-javadoc.jar" if javadoc_path and os.path.exists(javadoc_path) else None
        tests_path = filename_base + "-tests.jar" if tests_path and os.path.exists(tests_path) else None
        return jar_filename, pom_filename, sources_filename, javadoc_filename, tests_path

    # Specific
    @abstractmethod
    def apt(self, deb_file, distro, opts={}):
        raise NotImplementedError("Abstract")

    @abstractmethod
    def artifact(self, artifact_group, version, artifact_path, filename, opts={}):
        raise NotImplementedError("Abstract")

    @abstractmethod
    def helm(self, tar_path, opts={}):
        raise NotImplementedError("Abstract")

    @abstractmethod
    def maven(self, group_id, artifact_id, version,
              jar_path, pom_path,
              sources_path=None, javadoc_path=None, tests_path = None,
              should_sign = True,
              opts={}):
        raise NotImplementedError("Abstract")
