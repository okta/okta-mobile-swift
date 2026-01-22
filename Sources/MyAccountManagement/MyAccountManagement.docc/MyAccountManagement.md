# ``MyAccountManagement``

Library that exposes the MyAccount user account management capabilities from Okta. 

## Overview

## Updating

Updating this library to leverage a new version of the OpenAPI spec requires the following steps:

1. Clone the latest okta-management-openapi-spec repository
2. Using the current spec named `idp-oneOfInheritance-noExamples.yaml`, filter the referenced examples from the spec.
3. Save the output YAML file to `openapi.yaml`

> yq 'del(.. | select(has("example") or has("examples")).example, .. | select(has("example") or has("examples")).examples)' path/to/dist/current/idp-oneOfInheritance-noExamples.yaml > path/to/Sources/MyAccountManagement/openapi.yaml 

## Topics

