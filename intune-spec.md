<style>
body {
  font-family: Segoe UI,SegoeUI,Helvetica Neue,Helvetica,Arial,sans-serif;
  padding: 1em;
  margin: auto;
  max-width: 42em;
  background: #fefefe;
}
.protocol-table p {
  margin-top: 0px;
}
p {
  margin-top: 1rem;
  margin-bottom: 0px;
}
table {
  margin-top: 1rem;
  border: 1px solid #EAEAEA;
  border-collapse: collapse;
  width: 100%;
}
table, th, td {
  border-radius: 3px;
  padding: 5px;
}
th, td {
  font-size: .875rem;
  padding-top: 0.5rem;
  padding-bottom: 0.5rem;
  border: 1px solid #bbb;
  color: #2a2a2a;
}
th {
  background-color: #ededed;
  font-weight: 600;
}
td {
  padding: 0.5rem;
  background-color: #fff;
}
h1, h2, h3, h4, h5, h6 {
  font-weight: bold;
  color: #000;
}
h1 {
  font-size: 28px;
}
h2 {
  font-size: 24px;
}
h3 {
  font-size: 18px;
}
h4 {
  font-size: 16px;
}
h5 {
  font-size: 14px;
}
</style>

# Intune for Linux Specification

Intune for Linux enrollment and check-in protocol specification.

## Published Version

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Date</p>
   </th>
   <th>
   <p>Protocol Revision</p>
   </th>
   <th>
   <p>Revision Class</p>
   </th>
   <th>
   <p>Downloads</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>05/01/2025</p>
  </td>
  <td>
  <p>0.01</p>
  </td>
  <td>
  <p>New</p>
  </td>
  <td>
  <p>

  </p>
  </td>
 </tr>

 <tr>
  <td>
  <p>05/02/2025</p>
  </td>
  <td>
  <p>0.02</p>
  </td>
  <td>
  <p>details and status messages documented</p>
  </td>
  <td>
  <p>

  </p>
  </td>
 </tr>

 <tr>
  <td>
  <p>05/08/2025</p>
  </td>
  <td>
  <p>0.03</p>
  </td>
  <td>
  <p>Policy listing details documented</p>
  </td>
  <td>
  <p>

  </p>
  </td>
 </tr>

 <tr>
  <td>
  <p>05/12/2025</p>
  </td>
  <td>
  <p>0.04</p>
  </td>
  <td>
  <p>Status reporting details documented</p>
  </td>
  <td>
  <p>

  </p>
  </td>
 </tr>

 <tr>
  <td>
  <p>02/27/2026</p>
  </td>
  <td>
  <p>0.05</p>
  </td>
  <td>
  <p>Protocol corrections and compliance query documentation</p>
  </td>
  <td>
  <p>

  </p>
  </td>
 </tr>

</tbody></table>

# 1 Introduction

## 1.1 Glossary

- **Entra ID**: Microsoft’s cloud-based identity and access management service (formerly Azure AD).
- **Client**: The Linux device or agent initiating communication with Microsoft Intune.
- **Host**: A trusted Entra ID-joined device issuing On-Behalf-Of (OBO) token requests.
- **Enrollment**: The process of registering a Linux device with Microsoft Intune.
- **Check-in**: A post-enrollment protocol for policy compliance and configuration synchronization.
- **Intune Device ID**: The `deviceId` returned by the Linux enrollment endpoint and used for subsequent check-in operations.

## 1.2 References

### 1.2.1 Normative References

- [RFC6749](https://go.microsoft.com/fwlink/?LinkId=301486), The OAuth 2.0 Authorization Framework.
- [RFC4211](https://go.microsoft.com/fwlink/?LinkId=301568), Internet X.509 Public Key Infrastructure Certificate Request Message Format (CRMF).
- [RFC4648](https://go.microsoft.com/fwlink/?LinkId=90487), The Base16, Base32, and Base64 Data Encodings.
- [RFC8017](https://go.microsoft.com/fwlink/?linkid=2164409), PKCS #1: RSA Cryptography Specifications.

### 1.2.2 Informative References

- Microsoft Graph service principal endpoints API (`/servicePrincipals/{id}/endpoints`).

## 1.3 Overview

This document specifies the network protocol surface required to support
Microsoft Intune device management on Linux systems. It describes the service
discovery, enrollment, policy retrieval, status submission, and compliance
information query operations that a conforming Linux client MUST implement.

This specification is intended for protocol implementers. It defines request and
response shapes, required query parameters, authorization resource identifiers,
and processing expectations for each operation. The examples in this document
are illustrative and non-normative; when examples and normative sections differ,
the normative sections in [2 Protocol Details](#2-protocol-details) take
precedence.

## 1.4 Relationship to Other Protocols

This protocol is composed of HTTP operations across multiple Microsoft services:

- Microsoft Graph for Intune endpoint discovery.
- Intune Linux Enrollment Service for device enrollment.
- Intune Linux Device Check-in Service for details, policies, and status.
- IWService for compliance-state and noncompliant-rule retrieval.

Authorization for these operations relies on OAuth 2.0 bearer tokens obtained by
the host using On-Behalf-Of (OBO) flow semantics.

## 1.5 Prerequisites/Preconditions

Before invoking protocol operations in this document, the caller MUST:

1. Have an authenticated Entra ID context capable of obtaining bearer tokens for
   each required resource identifier.
2. Perform service endpoint discovery to obtain current Intune service URIs.
3. For check-in operations, possess a valid Intune Device ID returned by the
   enrollment operation.

## 1.6 Versioning and Capability Negotiation

This protocol does not define an explicit negotiation handshake. Version behavior
is driven by:

- `api-version` query parameters on each endpoint.
- `client-version` query parameters supplied by the calling client.
- Presence of discovered service endpoints (`providerName`) indicating
  operation availability.

## 1.7 Vendor-Extensible Fields

Unless otherwise specified, clients SHOULD ignore unrecognized response fields
and MUST preserve required protocol semantics for recognized fields.

This document does not define local client architecture, data persistence
strategy, scheduling model, or operating-system integration behavior.

## 1.8 Protocol Operation Sequence

This section describes how the protocol operations fit together as an end-to-end
device-management workflow.

### 1.8.1 Enrollment Sequence

Before a device can participate in policy processing, the caller performs:

1. Service endpoint discovery via Microsoft Graph to obtain Intune service URIs.
2. Device enrollment using the Enrollment resource (`enroll`).
3. Persistence of the returned Intune Device ID for subsequent check-in
   operations.

The output of enrollment is an Intune-enrolled device identity used by all
check-in and compliance operations.

### 1.8.2 Check-In and Reporting Sequence

After enrollment, a protocol-conforming check-in cycle consists of:

1. Submit device metadata using `details`.
2. Retrieve assigned policies using `policies`.
3. Evaluate policies locally and construct policy-status payloads.
4. Submit policy-status results using `status`.
5. Optionally query effective compliance information using `complianceInfo`.

The `status` operation reports per-policy and per-rule evaluation results,
whereas `complianceInfo` returns the service-evaluated compliance view.

### 1.8.3 Authorization Context by Operation

Operations require different OAuth resource audiences:

- Service endpoint discovery: Microsoft Graph (`00000003-0000-0000-c000-000000000000`)
- Enrollment: Intune Enrollment Application (`d4ebce55-015a-49b5-a083-c84d1797ae8c`)
- `details`, `policies`, `status`: Microsoft Intune Company Portal (`0000000a-0000-0000-c000-000000000000`)
- `complianceInfo`: IWService (`b8066b99-6e67-41be-abfa-75db1a2c8809`)

Callers SHOULD ensure the correct token audience is used for each operation
before message submission.

# 2 Protocol Details

## 2.1 Intune for Linux Resource Operations

The resources in this section define a lifecycle-oriented protocol surface: one
enrollment operation (`enroll`) and four post-enrollment operations (`details`,
`policies`, `status`, and `complianceInfo`). The operations are specified
individually below and are intended to be composed using the sequence described
in [1.8 Protocol Operation Sequence](#1.8-protocol-operation-sequence).

### 2.1.1 Enroll Resource (`enroll`)

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>POST</p>
  </td>
  <td>
  <p>2.1.1.1</p>
  </td>
  <td>
  <p>Enroll a device for Intune MDM policy enforcement.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.1.1 POST

This method is transported by an HTTP POST.

The method is invoked through the LinuxEnrollmentService URI discovered
via [Service Discovery](#service-endpoint-discovery-response-body).

##### 2.1.1.1.1 <a id="enroll-request-body"></a> Request Body

The request body contains the following JSON-formatted object.

<pre class="has-inner-focus">
<code class="lang-json">{
    "AppVersion": string,
    "DeviceName": string,
    "CertificateSigningRequest": string,
}
</code></pre>

__AppVersion__: The version string of the calling application. Required.

__DeviceName__: The friendly name of the device. Required.

__CertificateSigningRequest__: A property that contains a base64-encoded
[PKCS#10](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dvrj/6961b602-0255-438a-8e64-1ee6081d9b88#gt_30428780-593d-43f8-b187-58f64d2eae7d)
certificate request
[[RFC4211]](https://go.microsoft.com/fwlink/?LinkId=301568). The certificate
request MUST use an
[RSA](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dvrj/6961b602-0255-438a-8e64-1ee6081d9b88#gt_3f85a24a-f32a-4322-9e99-eba6ae802cd6)
[public key algorithm](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dvrj/6961b602-0255-438a-8e64-1ee6081d9b88#gt_46ef9374-f1be-4b5c-8389-489d594c7603)
[[RFC8017]](https://go.microsoft.com/fwlink/?linkid=2164409) with a 2048-bit
key, a SHA256WithRSAEncryption signature algorithm, and a SHA256 hash algorithm. Required.

##### 2.1.1.1.2 <a id="enroll-response-body"></a> Response Body

If the service successfully enrolls the device for Intune policy enforcement, an
HTTP 200 status code is returned. Additionally, the response body for the POST
response contains a JSON-formatted object, as defined below. See section
[2.1.1.1.3](#enrollment-processing-details) for processing details.

<pre class="has-inner-focus">
<code class="lang-json">{
    "deviceId": string,
    "certificate": {
        "thumbprint": string,
        "certBlob": byte array
    },
    "renewPeriod": int
}
</code></pre>

The service response MUST include `deviceId` and `certificate.certBlob`. Additional
fields, including `certificate.thumbprint` and `renewPeriod`, MAY be present.

__deviceId__: A UUID which uniquely identifies the Intune enrolled device. This is separate
from the Entra Id enrolled device Id.

__certificate__: A property with the following fields.

- __thumbprint__: The SHA1 hash of the certificate
[thumbprint](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dvrj/6961b602-0255-438a-8e64-1ee6081d9b88#gt_a8d3bb6c-a2e2-44ae-ba3b-58ca861ab74f).

- __certBlob__: An X.509 certificate signed by the Intune service as a base64-encoded
DER-encoded byte array [[RFC4648]](https://go.microsoft.com/fwlink/?LinkId=90487).

__renewPeriod__: The period in which renewal is valid.

##### 2.1.1.1.3 <a id="enrollment-processing-details"></a> Processing Details

On the client side, the following processing steps MUST be performed:

1. **Generate CSR**: A [PKCS#10] certificate signing request MUST be generated using an RSA 2048-bit key, signed with SHA256WithRSAEncryption.

2. **Prepare Enrollment Payload**:
   - `AppVersion`: MUST be populated with the application version string (e.g., `1.2405.17`).
   - `DeviceName`: SHOULD match the system hostname or other consistent identifier.
   - `CertificateSigningRequest`: MUST be base64-encoded with no surrounding PEM headers.

3. **Acquire Access Token**: The client MUST obtain a bearer token via the on-behalf-of flow targeting the `Intune Enrollment Application` resource ID.

4. **Submit Enrollment Request**: The client MUST send the request via HTTP POST to the `LinuxEnrollmentService` URI, using HTTPS with TLS 1.2 or higher.

5. **Parse Response**:
    - The client MUST extract the `deviceId` and persist it for future use.
    - The returned certificate MUST be re-assembled from the byte array and stored securely.
    - If present, `renewPeriod` SHOULD be recorded to determine certificate renewal intervals.

Upon receiving the enrollment request, the server performs the following steps:

1. **Validate Access Token**: The service ensures the bearer token is valid and scoped to the Intune Enrollment Application.
2. **Validate CSR**: The `CertificateSigningRequest` is parsed and validated against requirements:
   - RSA 2048-bit public key
   - SHA256WithRSAEncryption signature
3. **Generate Certificate**: If valid, a short-lived device management certificate is issued, signed by the Intune service.
4. **Store Device Record**: A device record is created in the Intune backend and associated with the authenticatated Entra Id device object.
5. **Return Response**: The `deviceId`, encoded certificate, and renewal period are returned to the client.
If any validation fails, an HTTP error status is returned.

### 2.1.2 <a id="2.1.2-details"></a> Details Resource (`details`)

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>POST</p>
  </td>
  <td>
  <p>2.1.2.1</p>
  </td>
  <td>
  <p>Supply device details for the Intune enrolled device.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.2.1 POST

This method is transported by an HTTP POST.

The method is invoked through the LinuxDeviceCheckinService URI discovered
via [Service Discovery](#service-endpoint-discovery-response-body).

##### 2.1.2.1.1 <a id="details-request-body"></a> Request Body

The request body contains the following JSON-formatted object.

<pre class="has-inner-focus">
<code class="lang-json">{
  "DeviceId": string,
  "DeviceName": string,
  "Manufacturer": string,
  "OSDistribution": string,
  "OSVersion": string,
}
</code></pre>

__DeviceId__: The Intune Device ID returned by [enroll](#enroll-response-body). Required.

__DeviceName__: The friendly name of the device. Required.

__Manufacturer__: The manufacturer of the device. Required.

__OSDistribution__: The Linux distribution of the device. Required.

__OSVersion__: The version string of the Linux distribution. Required.

##### 2.1.2.1.2 <a id="details-response-body"></a> Response Body

If the service successfully receives device details, an HTTP 200 status code is
returned. Additionally, the response body for the POST response contains a
JSON-formatted object, as defined below. See section
[2.1.2.1.3](#details-processing-details) for processing details.

<pre class="has-inner-focus">
<code class="lang-json">{
    "deviceFriendlyName": string
}
</code></pre>

__deviceFriendlyName__: The friendly name for the device.

##### 2.1.2.1.3 <a id="details-processing-details"></a> Processing Details

Upon receiving a `POST` request to the `details` sub-endpoint, the LinuxDeviceCheckinService performs the following actions:

1. **Validate Payload**:
   The server verifies that all required fields (`DeviceId`, `DeviceName`, `Manufacturer`, `OSDistribution`, and `OSVersion`) are present and non-empty. If any required field is missing or malformed, the service responds with a 400 Bad Request HTTP status.

2. **Normalize Input**:
   Input fields MAY be normalized or sanitized. For example, the `DeviceName` may be truncated to a maximum length or stripped of invalid characters for consistency across the portal interface.

3. **Update Device Metadata**:
   If the device is already registered with Intune (based on prior enrollment), the provided details are stored or updated in the Intune device record associated with the device’s ID or authentication context.

4. **Acknowledge with Friendly Name**:
   The response includes a `deviceFriendlyName`, which may be:
   - A sanitized version of the provided `DeviceName`, or
   - A name determined by Intune policy, tenant configuration, or service-side logic.

5. **No Token or Session Change**:
   This operation does not alter the device's registration state or authentication session. It is used solely for populating metadata for display in the Intune portal or for policy evaluation purposes.

If the device is unknown or not currently enrolled, the server MAY reject the request with an HTTP `401 Unauthorized`.

### 2.1.3 Status Resource (`status`)

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>POST</p>
  </td>
  <td>
  <p>2.1.3.1</p>
  </td>
  <td>
  <p>Report the status of Intune policy enforcement.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.3.1 POST

This method is transported by an HTTP POST.

The method is invoked through the LinuxDeviceCheckinService URI discovered
via [Service Discovery](#service-endpoint-discovery-response-body).

##### 2.1.3.1.1 <a id="status-request-body"></a> Request Body

The request body contains the following JSON-formatted object.

<pre class="has-inner-focus">
<code class="lang-json">{
  "DeviceId": string,
  "PolicyStatuses": array
}
</code></pre>

__DeviceId__: The Intune Device ID. Required.

__PolicyStatuses__: A list of statuses indicating policy enforcement compliance.

Each entry in the `PolicyStatuses` array is an object formatted as follows:

<pre class="has-inner-focus">
<code class="lang-json">{
    "Details": array,
    "LastStatusDateTime": string,
    "PolicyId": string
}
</code></pre>

- __Details__: An array of objects providing detailed compliance information for
individual rules within the policy. Each details object is formatted as follows:

  <pre class="has-inner-focus">
  <code class="lang-json">{
      "ActualValue": string,
      "ExpectedValue": string,
      "NewComplianceState": string,
      "OldComplianceState": string,
      "RuleId": string,
      "SettingDefinitionItemId": string,
      "ErrorCode": int,
      "ErrorType": int
  }
  </code></pre>

  - __ActualValue__: The actual value reported by the device.
  - __ExpectedValue__: The expected value as defined by the policy.
  - __NewComplianceState__: The current compliance state (for example, `Compliant`, `NonCompliant`, `Error`, or `Unknown`).
  - __OldComplianceState__: The previous compliance state before the current status update (for example `Unknown`).
  - __RuleId__: A UUID uniquely identifying the rule being evaluated.
  - __SettingDefinitionItemId__: An identifier for the specific configuration item within the policy.
  - __ErrorCode__: Optional. An integer indicating the error code associated with the compliance check (0 if no error).
  - __ErrorType__: Optional. An integer indicating the type of error encountered (0 if no error).

- __LastStatusDateTime__: The timestamp indicating when the status was last reported.

- __PolicyId__: A unique identifier for the policy being reported.

These values are
derived from policies retrieved via the [policies](#policies-response-body)
endpoint.

##### 2.1.3.1.2 <a id="status-response-body"></a> Response Body

If the request is successful, an HTTP 200 status code is
returned. Additionally, the response body for the POST response contains a
JSON-formatted object, as defined below. See section
[2.1.3.1.3](#status-processing-details) for processing details.

<pre class="has-inner-focus">
<code class="lang-json">{
    "PolicyStatuses": array
}
</code></pre>

__PolicyStatuses__: A list of statuses for policy enforcement actions. The
response echoes the received statuses to acknowledge receipt and processing.

##### 2.1.3.1.3 <a id="status-processing-details"></a> Processing Details

Upon receiving a valid request, the server performs the following processing steps:

1. **Device Validation**:
   - The `DeviceId` is extracted from the request body.
   - The server verifies that the device is known and enrolled with Intune.
   - If the `DeviceId` is invalid or not recognized, the server returns an HTTP 400 Bad Request with a JSON error payload indicating `"Device validation failed"`.

2. **Policy Retrieval**:
   - If the device is valid, the server retrieves any pending, active, or recently completed policy enforcement tasks associated with the device.
   - This includes configuration profiles, compliance checks, and application assignments scheduled for enforcement on the device.

3. **State Considerations**:
   - If the device has not yet submitted host metadata via the [`details`](#2.1.2-details) endpoint, or is not in a fully enrolled state, the server may return an empty `PolicyStatuses` array.
   - Some policies may only appear after the device has been evaluated for compliance or has been assigned applicable configuration.

4. **Response Construction**:
   - The server responds with HTTP status `200 OK` if the request is valid and the device is recognized.
    - The response body contains a `PolicyStatuses` array. If no actions are pending or applicable, this array is empty.
    - The schema of individual `PolicyStatuses` entries MAY vary based on tenant policy configurations and device state.

5. **Serialization Requirements**:
   - Clients MUST serialize status payload fields using the exact property names in [2.1.3.1.1](#status-request-body).
   - Clients SHOULD treat `ErrorCode` and `ErrorType` as optional fields.

This endpoint is used to report the current compliance status of policies and
does not trigger policy enforcement. Clients should ensure that devices have
fetched the latest policy definitions via the [`policies`](#policies) endpoint
before submitting compliance status reports.

### 2.1.4 Intune Service Endpoint Discovery Resource

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>GET</p>
  </td>
  <td>
  <p>2.1.4.1</p>
  </td>
  <td>
  <p>List the service endpoints associated with Intune.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.4.1 GET

This method is transported by an HTTP GET.

The method is invoked through the Microsoft Graph.

##### 2.1.4.1.1 <a id="service-endpoint-discovery-request-body"></a> Request Body

Empty.

##### 2.1.4.1.2 <a id="service-endpoint-discovery-response-body"></a> Response Body

The response body contains the following JSON-formatted object.

<pre class="has-inner-focus">
<code class="lang-json">{
    "value": object array,
}
</code></pre>

__value__: A list of discovered services, each service formatted as follows:

<pre class="has-inner-focus">
<code class="lang-json">{
    "id": string,
    "deletedDateTime": string,
    "capability": string,
    "providerId": string,
    "providerName": string,
    "providerResourceId": string,
    "uri": string,
}
</code></pre>

- __id__: A UUID which uniquely identifies the service endpoint.

- __deletedDateTime__: Indicating when a service endpoint has been removed.

- __capability__: A unique string which identifies the capabilites of the service endpoint.

- __providerId__: A UUID which uniquely identifies the service provider application
client-id.

- __providerName__: A unique name which identifies the service endpoint.

- __providerResourceId__: A UUID which identifies the service endpoint resource.

- __uri__: A string URI used to invoke the service endpoint.

##### 2.1.4.1.3 <a id="service-endpoint-discovery-details"></a> Processing Details

The service endpoint discovery request MUST be issued by an Entra ID-hosted client using an access token scoped to the Microsoft Graph resource.

Upon a successful response, the client MUST:

1. **Filter by Service Name**: The client MUST parse the `"value"` array and extract service objects based on `providerName`:
   - `LinuxEnrollmentService`
   - `LinuxDeviceCheckinService`
   - `IWService`

2. **Record URIs**: For each relevant service, the client MUST record the following:
   - `uri`: Used for subsequent service invocation.
   - `providerName`: Used to select the target service endpoint.

3. **Cache Results Appropriately**: Clients SHOULD cache the discovered endpoints in memory for the lifetime of the session or until invalidated. Service discovery SHOULD be repeated each time a checkin is performed.

If the service does not return the expected services, the client MUST treat the response as non-actionable and fail gracefully.

### 2.1.5 <a id="policies"></a> Policies Resource (`policies`)

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>GET</p>
  </td>
  <td>
  <p>2.1.5.1</p>
  </td>
  <td>
  <p>Retrieve device policies for the Linux Intune enrolled device.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.5.1 GET

This method is transported by an HTTP GET.

The method is invoked through the LinuxDeviceCheckinService URI discovered via [Service Discovery](#service-endpoint-discovery-response-body).

##### 2.1.5.1.1 <a id="policies-request-body"></a> Request Body

Empty.

##### 2.1.5.1.2 <a id="policies-response-body"></a> Response Body

The response body contains the following JSON-formatted object.

<pre class="has-inner-focus">
<code class="lang-json">{
  "policies": [
    {
      "accountId": string,
      "policyId": string,
      "description": string,
      "version": int,
      "policyType": string,
      "policySettings": object array,
    }
  ]
}
</code></pre>

__accountId__: The account identifier associated with policy assignment.

__policyId__: A unique identifier for the policy.

__description__: A brief description of the policy.

__version__: The version number of the policy.

__policyType__: The type of policy (e.g., Configuration).

__policySettings__: An array of policy settings, formatted as follows:

<pre class="has-inner-focus">
<code class="lang-json">{
    "settingDefinitionReportingId": string,
    "settingDefinitionItemId": string,
    "cspPath": string,
    "cspPathId": string,
    "ruleId": string,
    "ruleName": string,
    "value": string
}
</code></pre>

- __settingDefinitionReportingId__: A unique identifier used for reporting the setting's status.

- __settingDefinitionItemId__: An identifier for the specific configuration item within the policy.

- __cspPath__: A path indicating the Configuration Service Provider (CSP) namespace and the specific setting being configured.

- __cspPathId__: A unique identifier for the CSP path, used for internal processing.

- __ruleId__: A UUID that uniquely identifies the rule enforcing the setting.

- __ruleName__: A human-readable name for the rule (may be null if unspecified).

- __value__: The configured value for the setting (e.g., a numeric value or a string).

Fields such as `settingDefinitionReportingId` and `ruleName` MAY be present in
service responses and are not required for policy-status submission.

##### 2.1.5.1.3 Processing Details

Upon receiving a `GET` request to the `policies` endpoint, the LinuxDeviceCheckinService performs the following actions:

1. **Authorization Validation**: Verifies that the bearer token is valid and scoped to the Microsoft Intune Company Portal Application.

2. **Policy Retrieval**: Fetches the current policies assigned to the device. If no policies are available, an empty `policies` array is returned.

3. **Response Construction**: Constructs a JSON object containing the device's policy details, including settings and their values.

4. **Error Handling**: If the request is unauthorized or the token is invalid, an HTTP 401 Unauthorized status is returned.

### 2.1.6 Compliance Information Resource (`complianceInfo`)

The following HTTP methods are allowed to be performed on this resource.

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>HTTP method</p>
   </th>
   <th>
   <p>Section</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>GET</p>
  </td>
  <td>
  <p>2.1.6.1</p>
  </td>
  <td>
  <p>Query compliance state and noncompliant rules for an Intune enrolled device.</p>
  </td>
 </tr>
</tbody></table>

#### 2.1.6.1 GET

This method is transported by an HTTP GET.

The method is invoked through the IWService URI discovered
via [Service Discovery](#service-endpoint-discovery-response-body).

##### 2.1.6.1.1 Request Body

Empty.

##### 2.1.6.1.2 <a id="compliance-info-response-body"></a> Response Body

The response is an OData JSON object describing the device record. The following
fields are relevant to compliance evaluation:

- `ComplianceState`: Current overall compliance state.
- `NoncompliantRules`: A list of noncompliant rules, each rule including fields
  such as `SettingID`, `ExpectedValue`, and optional metadata (`Title`,
  `Description`, `MoreInfoUri`).

##### 2.1.6.1.3 Processing Details

1. **Invocation URI**:
   - `GET {IWService}/Devices(guid'{intune-device-id}')?api-version=16.4&ssp=LinuxCP&ssp-version={client-version}&os=Linux&mgmt-agent=mdm`
2. **Authorization Validation**:
   - The bearer token MUST be scoped to the IWService resource (`b8066b99-6e67-41be-abfa-75db1a2c8809`).
3. **Response Interpretation**:
   - The response includes compliance state information and noncompliant rule data for the specified device.

# 3 Protocol Examples (Non-Normative)

The examples in this section are provided to illustrate wire format and field
usage. In case of conflict, section [2 Protocol Details](#2-protocol-details)
is normative.

## 3.1 Enroll Device (`enroll`)

Enroll the authenticated Linux host for Intune policy enforcement.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
POST {EnrollmentServiceURI}/enroll?api-version=1.0&client-version=1.2405.17
</span></code></pre>

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
Id enrolled host. The requested resource MUST be the Intune Enrollment
Application UUID and the on-behalf-of client-id MUST be the Microsoft Intune
Company Portal for Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>d4ebce55-015a-49b5-a083-c84d1797ae8c</p>
  </td>
  <td>
  <p>Intune Enrollment Application</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

In the request body, supply a JSON representation of a Linux enrollment
request, as specified in [section 2.1.1.1.1](#enroll-request-body).

### Expected Response

If successful, this method returns a 200 response code and a signed
certificate in the response body, as specified in
[section 2.1.1.1.2](#enroll-response-body).

### Example Exchange

The following example shows a request to the Linux Enrollment Service endpoint
to enroll the host for policy enforcement ([section 2.1.1.1.1](#enroll-request-body))
and the response ([section 2.1.1.1.2](#enroll-response-body)).

### Example Request

Here is an example of the request.

<blockquote>
<strong>Note:</strong> The request object shown here is shortened for
readability.
</blockquote>

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService
/LinuxMDM/LinuxEnrollmentService/enroll?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "AppVersion": "1.2405.17",
  "DeviceName": "MyPC",
  "CertificateSigningRequest": "MIICd...LWH31"
}
</code></pre>

### Example Response

Here is an example of the response.

<blockquote>
<strong>Note:</strong> The response object shown here is shortened for
readability.
</blockquote>

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
    "deviceId": "0f1212dc-d64d-4b55-9bc8-39bdd82a92de",
    "certificate": {
        "thumbprint": "8524BFCF446820D09D4487B342B915C2BA682AFE",
        "certBlob": [48,130,4...202,228,58],
        "renewPeriod":181
    }
}
</code></pre>

## 3.2 Submit Device Details (`details`)

Supply device details for the Linux Intune enrolled host.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
POST {LinuxDeviceCheckinServiceURI}/details?api-version=1.0&client-version=1.2405.17
</span></code></pre>

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
Id enrolled host. The requested resource MUST be the Microsoft Intune Company
Portal UUID and the on-behalf-of client-id MUST be the Microsoft Intune
Company Portal for Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>0000000a-0000-0000-c000-000000000000</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

In the request body, supply a JSON representation of a Linux device details
request, as specified in [section 2.1.2.1.1](#details-request-body).

### Expected Response

If successful, this method returns a 200 response code and a device friendly
name in the response body, as specified in
[section 2.1.2.1.2](#details-response-body).

### Example Exchange

The following example shows a request to the Linux Device Checkin Service endpoint
to supply device details for the host ([section 2.1.2.1.1](#details-request-body))
and the response ([section 2.1.2.1.2](#details-response-body)).

### Example Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService
/LinuxMdm/LinuxDeviceCheckinService/details?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "DeviceId": "8077ec2c-abca-46d2-9621-a0f06a460f96",
  "DeviceName": "openSUSE-Laptop",
  "Manufacturer": "Lenovo",
  "OSDistribution": "openSUSE Tumbleweed",
  "OSVersion": "20241211"
}
</code></pre>

### Example Response

Here is an example of the response.

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
  "deviceFriendlyName": ""
}
</code></pre>

## 3.3 Submit Policy Status (`status`)

Check the status of Linux Intune policy enforcement.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
POST {LinuxDeviceCheckinServiceURI}/status?api-version=1.0&client-version=1.2405.17
</span></code></pre>

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
Id enrolled host. The requested resource MUST be the Microsoft Intune Company
Portal UUID and the on-behalf-of client-id MUST be the Microsoft Intune
Company Portal for Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>0000000a-0000-0000-c000-000000000000</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

In the request body, supply a JSON representation of a Linux policy status
request, as specified in [section 2.1.3.1.1](#status-request-body).

### Expected Response

If successful, this method returns a 200 response code and a list of policy statuses
in the response body, as specified in [section 2.1.3.1.2](#status-response-body).

### Example Exchange

The following example shows a request to the Linux Device Checkin Service endpoint
to check the policy status for the host ([section 2.1.3.1.1](#status-request-body))
and the response ([section 2.1.3.1.2](#status-response-body)).

### Example Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService
/LinuxMdm/LinuxDeviceCheckinService/status?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "DeviceId": "8077ec2c-abca-46d2-9621-a0f06a460f96",
    "PolicyStatuses": [
        {
            "Details": [
                {
                    "ActualValue": "IyEvYmluL3NoCgpleGl0IDAK",
                    "ExpectedValue": "IyEvYmluL3NoCgpleGl0IDAK",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "89da1038-5ebf-4981-8bca-40e284b60872",
                    "SettingDefinitionItemId": "linux_customconfig_script"
                }
            ],
            "LastStatusDateTime": "2025-05-12T15:52:31+00:00",
            "PolicyId": "6199d7d9-50dc-4bc6-bc83-0dc0a7dcfa0c"
        },
        {
            "Details": [
                {
                    "ActualValue": "",
                    "ExpectedValue": "",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ce8d2180-58a4-4d92-8052-5318a74ec35b",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_maximumversion"
                },
                {
                    "ActualValue": "",
                    "ExpectedValue": "",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "563e0ace-a342-45d2-a5f8-4769660607a3",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_minimumversion"
                },
                {
                    "ActualValue": "ubuntu",
                    "ExpectedValue": "ubuntu",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ece25d4a-6d2f-4c88-9051-06e044fb9740",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_$type"
                },
                {
                    "ActualValue": "True",
                    "ExpectedValue": "True",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "cf4fb087-40ca-49af-a1d2-2b9163f0ded5",
                    "SettingDefinitionItemId": "linux_deviceencryption_required"
                },
                {
                    "ActualValue": "4",
                    "ExpectedValue": "4",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "6277da27-719c-4d82-a659-6e652041a829",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumdigits"
                },
                {
                    "ActualValue": "8",
                    "ExpectedValue": "8",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "f91a4914-1630-4f62-b33a-ca8a48a7b6d1",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumlength"
                },
                {
                    "ActualValue": "2",
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ec02c30f-f361-48d7-bfbb-f5b0c0f0f3fc",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumlowercase"
                },
                {
                    "ActualValue": "2",
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "573f4d7d-9eda-4e35-81ab-6b0d240e0750",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumsymbols"
                },
                {
                    "ActualValue": "2",
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "29500bbf-127a-4212-a2da-5cd86132b3d9",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumuppercase"
                }
            ],
            "LastStatusDateTime": "2025-05-12T15:52:31+00:00",
            "PolicyId": "f7101810-6170-491f-a40b-322d1cb363c1"
        }
    ]
}
</code></pre>

### Example Response

Here is an example of the response.

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
    "PolicyStatuses": [
        {
            "Details": [
                {
                    "ActualValue": "IyEvYmluL3NoCgpleGl0IDAK",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "IyEvYmluL3NoCgpleGl0IDAK",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "89da1038-5ebf-4981-8bca-40e284b60872",
                    "SettingDefinitionItemId": "linux_customconfig_script"
                }
            ],
            "LastStatusDateTime": "2025-05-12T15:52:31+00:00",
            "PolicyId": "6199d7d9-50dc-4bc6-bc83-0dc0a7dcfa0c"
        },
        {
            "Details": [
                {
                    "ActualValue": "",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ce8d2180-58a4-4d92-8052-5318a74ec35b",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_maximumversion"
                },
                {
                    "ActualValue": "",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "563e0ace-a342-45d2-a5f8-4769660607a3",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_minimumversion"
                },
                {
                    "ActualValue": "ubuntu",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "ubuntu",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ece25d4a-6d2f-4c88-9051-06e044fb9740",
                    "SettingDefinitionItemId": "linux_distribution_alloweddistros_item_$type"
                },
                {
                    "ActualValue": "True",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "True",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "cf4fb087-40ca-49af-a1d2-2b9163f0ded5",
                    "SettingDefinitionItemId": "linux_deviceencryption_required"
                },
                {
                    "ActualValue": "4",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "4",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "6277da27-719c-4d82-a659-6e652041a829",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumdigits"
                },
                {
                    "ActualValue": "8",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "8",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "f91a4914-1630-4f62-b33a-ca8a48a7b6d1",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumlength"
                },
                {
                    "ActualValue": "2",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "ec02c30f-f361-48d7-bfbb-f5b0c0f0f3fc",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumlowercase"
                },
                {
                    "ActualValue": "2",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "573f4d7d-9eda-4e35-81ab-6b0d240e0750",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumsymbols"
                },
                {
                    "ActualValue": "2",
                    "ErrorCode": 0,
                    "ErrorType": 0,
                    "ExpectedValue": "2",
                    "NewComplianceState": "Compliant",
                    "OldComplianceState": "Unknown",
                    "RuleId": "29500bbf-127a-4212-a2da-5cd86132b3d9",
                    "SettingDefinitionItemId": "linux_passwordpolicy_minimumuppercase"
                }
            ],
            "LastStatusDateTime": "2025-05-12T15:52:31+00:00",
            "PolicyId": "f7101810-6170-491f-a40b-322d1cb363c1"
        }
    ]
}
</code></pre>

## 3.4 Discover Intune Service Endpoints

List the service endpoints associated with Intune.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
GET {MSGraph}/v1.0/servicePrincipals/appId=0000000a-0000-0000-c000-000000000000/endpoints
</span></code></pre>

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
Id enrolled host. The requested resource MUST be the Microsoft Graph UUID and
the on-behalf-of client-id MUST be the Microsoft Intune Company Portal for
Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>00000003-0000-0000-c000-000000000000</p>
  </td>
  <td>
  <p>Microsoft Graph</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

Empty.

### Expected Response

If successful, this method returns a 200 response code a json list of
service endpoints, as specified in
[section 2.1.4.1.2](#service-endpoint-discovery-response-body).

### Example Exchange

The following example shows a response from the Microsoft Graph for Intune
service endpoints ([section 2.1.4.1.2](#service-endpoint-discovery-response-body)).

### Example Request

Empty.

### Example Response

Here is an example of the response.

<blockquote>
<strong>Note:</strong> The response object shown here is shortened for
readability.
</blockquote>

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#servicePrincipals('appId%3D0000000a-0000-0000-c000-000000000000')/endpoints",
    "@microsoft.graph.tips": "Use $select to choose only the properties your app needs, as this can lead to performance improvements. For example: GET servicePrincipals('<key>')/endpoints?$select=capability,providerId",
    "value": [
        ...
        {
            "id": "2ebecc54-c89c-41e9-9df1-82fd8544a62b",
            "deletedDateTime": null,
            "capability": "LinuxEnrollmentService",
            "providerId": "0000000a-0000-0000-c000-000000000000",
            "providerName": "LinuxEnrollmentService",
            "providerResourceId": "9bcfcd1f-e173-472a-977b-338d25cb16e4",
            "uri": "https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService/LinuxMDM/LinuxEnrollmentService"
        },
        {
            "id": "6bf599bd-a2c2-46f4-9ee3-7a54712d6725",
            "deletedDateTime": null,
            "capability": "LinuxDeviceCheckinService",
            "providerId": "0000000a-0000-0000-c000-000000000000",
            "providerName": "LinuxDeviceCheckinService",
            "providerResourceId": "39c1e9b8-a589-49c7-8ccd-d16548ac78e1",
            "uri": "https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService/LinuxMdm/LinuxDeviceCheckinService"
        },
        ...
    ]
}
</code></pre>

## 3.5 Retrieve Policies (`policies`)

Retrieve device policies for the Linux Intune enrolled device.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
GET {LinuxDeviceCheckinServiceURI}/policies/{intune-device-id}?api-version=1.0&client-version=1.2405.17
</span></code></pre>

The request URL must utilize the `intune-device-id` provided during [Intune enrollment](#enroll-response-body).

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
Id enrolled host. The requested resource MUST be the Microsoft Intune Company
Portal UUID and the on-behalf-of client-id MUST be the Microsoft Intune
Company Portal for Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>0000000a-0000-0000-c000-000000000000</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

Empty.

### Expected Response

If successful, this method returns a 200 response code and a list of policies, as specified in
[section 2.1.5.1.2](#policies-response-body).

### Example Exchange

The following example shows a request to the Linux Device Checkin Service endpoint
to request policies for the host ([section 2.1.5.1.1](#policies-request-body))
and the response ([section 2.1.5.1.2](#policies-response-body)).

### Example Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">GET https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService
/LinuxMdm/LinuxDeviceCheckinService/policies/e82e80fe-1654-4766-848e-5e4db9a941ca?api-version=1.0&client-version=1.2405.17
</code></pre>

### Example Response

Here is an example of the response.

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
    "policies": [
        {
            "accountId": "1c2e9bb8-e414-4c34-8099-c418da11fed7",
            "description": "",
            "policyId": "6199d7d9-50dc-4bc6-bc83-0dc0a7dcfa0c",
            "policySettings": [
                {
                    "cspPath": "com.microsoft.manage.LinuxMdm/CustomConfig/ExecutionContext",
                    "cspPathId": "06e9a9b2-c7c1-adb6-97a0-92d2252471f3",
                    "ruleId": "c2586150-9f54-4df5-b380-1fb859e80453",
                    "ruleName": null,
                    "settingDefinitionItemId": "linux_customconfig_executioncontext",
                    "settingDefinitionReportingId": "efcc8ee0-59c0-d131-2f84-66ee74b42b76",
                    "value": "root"
                },
                {
                    "cspPath": "com.microsoft.manage.LinuxMdm/CustomConfig/ExecutionFrequency",
                    "cspPathId": "58d19221-5453-8470-9d27-2958af46929a",
                    "ruleId": "da026c44-bf31-4d94-a8f9-e86f214372b4",
                    "ruleName": null,
                    "settingDefinitionItemId": "linux_customconfig_executionfrequency",
                    "settingDefinitionReportingId": "b91dfb94-3b90-99c4-213e-91ddd841dac6",
                    "value": "10080"
                },
                {
                    "cspPath": "com.microsoft.manage.LinuxMdm/CustomConfig/ExecutionRetries",
                    "cspPathId": "6d36cb3a-f3cd-4189-6362-f7eafc25a01d",
                    "ruleId": "a56d05f5-43c4-478b-a1df-f9fd55fd9791",
                    "ruleName": null,
                    "settingDefinitionItemId": "linux_customconfig_executionretries",
                    "settingDefinitionReportingId": "f2a8e32f-3466-4a41-9f79-8fcf0d408f1f",
                    "value": "3"
                },
                {
                    "cspPath": "com.microsoft.manage.LinuxMdm/CustomConfig/Script",
                    "cspPathId": "24011ceb-c800-5975-b6ef-f0ceaf1a40f5",
                    "ruleId": "89da1038-5ebf-4981-8bca-40e284b60872",
                    "ruleName": null,
                    "settingDefinitionItemId": "linux_customconfig_script",
                    "settingDefinitionReportingId": "dcdf28eb-a3dc-763b-a0f7-83552ffdd00c",
                    "value": "IyEvYmluL3NoCgpleGl0IDAK"
                }
            ],
            "policyType": "Configuration",
            "version": 9
        }
    ]
}
</code></pre>

## 3.6 Query Compliance Information (`complianceInfo`)

Query compliance state and noncompliant rules for the Linux Intune enrolled device.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
GET {IWServiceURI}/Devices(guid'{intune-device-id}')?api-version=16.4&ssp=LinuxCP&ssp-version=1.2405.17&os=Linux&mgmt-agent=mdm
</span></code></pre>

The request URL must utilize the `intune-device-id` provided during [Intune enrollment](#enroll-response-body).

### Request Headers

<table class="protocol-table"><thead>
  <tr>
   <th>
   <p>Name</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>Content-type</p>
  </td>
  <td>
  <p>application/json</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>Authorization</p>
  </td>
  <td>
  <p>Bearer {token}. Required.</p>
  </td>
 </tr>
</tbody></table>

The authorization token MUST be granted via an on-behalf-of flow from an Entra
ID enrolled host. The requested resource MUST be the IWService UUID and the
on-behalf-of client-id MUST be the Microsoft Intune Company Portal for Linux UUID.

<table class="protocol-table"><thead>

  <tr>
   <th>
   <p>UUID</p>
   </th>
   <th>
   <p>Description</p>
   </th>
  </tr>
 </thead><tbody>
 <tr>
  <td>
  <p>b8066b99-6e67-41be-abfa-75db1a2c8809</p>
  </td>
  <td>
  <p>IWService</p>
  </td>
 </tr>
 <tr>
  <td>
  <p>b743a22d-6705-4147-8670-d92fa515ee2b</p>
  </td>
  <td>
  <p>Microsoft Intune Company Portal for Linux</p>
  </td>
 </tr>
</tbody></table>

### Request Body

Empty.

### Expected Response

If successful, this method returns a 200 response code and an OData JSON object
representing the Intune device record, as specified in
[section 2.1.6.1.2](#compliance-info-response-body).

### Example Exchange

The following example shows a request to the IWService endpoint to query
compliance information for the host.

### Example Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">GET https://fef.msua08.manage.microsoft.com/ReportingService/DataWarehouseFEService
/deviceservice/Devices(guid'8077ec2c-abca-46d2-9621-a0f06a460f96')?api-version=16.4&ssp=LinuxCP&ssp-version=1.2405.17&os=Linux&mgmt-agent=mdm
</code></pre>

### Example Response

Here is an example of the response.

<blockquote>
<strong>Note:</strong> The response object shown here is shortened for
readability.
</blockquote>

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
    "ComplianceState": "Compliant",
    "NoncompliantRules": []
}
</code></pre>
