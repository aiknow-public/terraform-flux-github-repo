This terraform module configures an existing git repo to be integrated in our flux stack.
It creates:
- a flux repo object 
- a github deploy key for that repo (stored in a k8s secret)
- a flux kustomization
- a flux receiver to be used in a github webhook
- a parameter store object containing the values for the webhook config in github

> The github webhook has to be manually created, the required data can be found in the parameter store.