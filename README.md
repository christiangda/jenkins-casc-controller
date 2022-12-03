# jenkins-casc-controller

Jenkins Configuration as a Code (CasC) controller container image. I used this to test different CasC configurations for Jenkins.

## Related Repositories

* [My jenkins-shared-library](https://github.com/christiangda/jenkins-shared-library)

## Repository Features

* [x] Script to bootstrap and run locally [run-local.sh](run-local.sh)
* [x] Script to update Jenkins plugins [update-plugins.sh](update-plugins.sh)
* [x] Script to check Jenkins CasC env vars during startup [entrypoint.sh](entrypoint.sh)

## Jenkins CasC features

* [x] Jenkins SAML V2 Security realm using [AWS IAM Identity Center (successor to AWS Single Sign-On)](https://docs.aws.amazon.com/singlesignon/index.html) [SAML - plugin](https://plugins.jenkins.io/saml/)
* [x] Jenkins GitHub [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/) [GitHub Branch Source - plugin](https://plugins.jenkins.io/github-branch-source/)

## How to use this image

```bash
./run-local.sh
```

## License

This module is released under the Apache License Version 2.0:

* [http://www.apache.org/licenses/LICENSE-2.0.html](http://www.apache.org/licenses/LICENSE-2.0.html)
