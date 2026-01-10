import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate(
    "new_sdk.json"
)

firebase_admin.initialize_app(cred)