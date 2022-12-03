# jenkins-casc-controller

Jenkins Configuration as a Code (CasC) controller container image. I used this to test different CasC configurations for Jenkins.

## Related Repositories

* [My jenkins-shared-library](https://github.com/christiangda/jenkins-shared-library)

## Repository Features

* [x] Script to bootstrap and run locally [run-local.sh](run-local.sh)
* [x] Script to update Jenkins plugins [update-plugins.sh](update-plugins.sh)
* [x] Script to check Jenkins CasC env vars during startup [entrypoint.sh](entrypoint.sh)

## Jenkins CasC features

* [x] Jenkins SAML V2 Security realm using [Google Workspace SAML](https://support.google.com/a/answer/12032922?product_name=UnuFlow&hl=en&visit_id=638056917241119327-4119517229&rd=1&src=supportwidget0&hl=en) [SAML - plugin](https://plugins.jenkins.io/saml/)
* [x] Jenkins GitHub [Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/) [GitHub Branch Source - plugin](https://plugins.jenkins.io/github-branch-source/)

## Environment Variables

Please create a file `local_env_vars` with the following variables:

* `JCASC_GITHUB_OAUTH_KEY` --> GitHub OAuth key encoded in base64
* `JCASC_GITHUB_OAUTH_SECRET` --> GitHub OAuth secret encoded in base64
* `JCASC_GITHUB_SSH_PRIVATE_KEY` --> GitHub SSH private key encoded in base64
* `JCASC_SAML_XML` --> SAML XML encoded in base64

### References

* <https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/docs/features/secrets.adoc>

## How to use this image

```bash
./run-local.sh
```

## Jobs DSL Information in local

* [jenkins.local - job DSL](https://jenkins.local/plugin/job-dsl/api-viewer/index.html)

## License

This module is released under the Apache License Version 2.0:

* [http://www.apache.org/licenses/LICENSE-2.0.html](http://www.apache.org/licenses/LICENSE-2.0.html)
