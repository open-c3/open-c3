import requests
import json
from ucloud.core import auth

class Projectid_api():
    
    def __init__(self, public_key, private_key):
        self.public_key = public_key
        self.private_key = private_key
    
    url = 'https://api.ucloud.cn'

    def init_params(self):
        cred = auth.Credential(
            self.public_key,
            self.private_key,
        )
        params = {"Action": "GetProjectList"}
        signature = cred.verify_ac(params)
        params["Signature"] = signature
        return params

    def get_projectid_info(self):
        params = self.init_params()
        try:
            responsed = requests.get(Projectid_api.url, params=params).json()
            projectid_list = responsed["ProjectSet"]
            return projectid_list
        except Exception as e:
            print(e)
            raise

