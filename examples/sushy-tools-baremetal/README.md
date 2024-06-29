# How to use
Make sure to set modify the secret to suit your nodes. Both currently supported BMC options are shown in the `secret.yaml` file. Currently the service is a statically assigned ClusterIP as the Ironic container has hard coded DNS, but this should be fixable.
## Recommendations 
- I recommend deploying the secret with a tool such as external DNS, in order to make use of its templating functionality.
