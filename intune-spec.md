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

Intune for Linux enrollment and checkin specification

## Terminology

- **Entra ID**: Microsoft’s cloud-based identity and access management service (formerly Azure AD).
- **Client**: The Linux device or agent initiating communication with Microsoft Intune.
- **Host**: A trusted Entra ID-joined device issuing On-Behalf-Of (OBO) token requests.
- **Enrollment**: The process of registering a Linux device with Microsoft Intune.
- **Check-in**: A post-enrollment protocol for policy compliance and configuration synchronization.

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

</tbody></table>

# 1 Introduction

This document describes the protocol and implementation requirements for supporting
Microsoft Intune device management on Linux systems. It outlines service discovery,
enrollment, and device check-in procedures for Linux clients integrating with
Microsoft Intune using native APIs.

# 2 Protocol Details

## 2.1 Intune for Linux Details

### 2.1.1 enroll

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
        "certBlob": byte array,
    },
    "renewPeriod": int
}
</code></pre>

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
   - The `renewPeriod` MUST be recorded to determine certificate renewal intervals.

Upon receiving the enrollment request, the server performs the following steps:

1. **Validate Access Token**: The service ensures the bearer token is valid and scoped to the Intune Enrollment Application.
2. **Validate CSR**: The `CertificateSigningRequest` is parsed and validated against requirements:
   - RSA 2048-bit public key
   - SHA256WithRSAEncryption signature
3. **Generate Certificate**: If valid, a short-lived device management certificate is issued, signed by the Intune service.
4. **Store Device Record**: A device record is created in the Intune backend and associated with the authenticatated Entra Id device object.
5. **Return Response**: The `deviceId`, encoded certificate, and renewal period are returned to the client.
If any validation fails, an HTTP error status is returned.

### 2.1.2 <a id="2.1.2-details"></a> details

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
  "DeviceName": string,
  "Manufacturer": string,
  "OSDistribution": string,
  "OSVersion": string,
}
</code></pre>

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
   The server verifies that all required fields (`DeviceName`, `Manufacturer`, `OSDistribution`, and `OSVersion`) are present and non-empty. If any required field is missing or malformed, the service responds with a 400 Bad Request HTTP status.

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

### 2.1.3 status

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
  <p>Check the status of Intune policy enforcement.</p>
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
  "DeviceId": string
}
</code></pre>

__DeviceId__: The Intune Device ID. Required.

##### 2.1.3.1.2 <a id="status-response-body"></a> Response Body

If the request is successful, an HTTP 200 status code is
returned. Additionally, the response body for the POST response contains a
JSON-formatted object, as defined below. See section
[2.1.3.1.3](#status-processing-details) for processing details.

<pre class="has-inner-focus">
<code class="lang-json">{
    "policyStatuses": array
}
</code></pre>

__policyStatuses__: A list of statuses for policy enforcement actions.

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
   - If the device has not yet submitted host metadata via the [`details`](#2.1.2-details) endpoint, or is not in a fully enrolled state, the server may return an empty `policyStatuses` array.
   - Some policies may only appear after the device has been evaluated for compliance or has been assigned applicable configuration.

4. **Response Construction**:
   - The server responds with HTTP status `200 OK` if the request is valid and the device is recognized.
   - The response body contains a `policyStatuses` array. If no actions are pending or applicable, this array is empty.
   - The schema of individual `policyStatuses` entries is currently undocumented and may vary based on tenant policy configurations and device state.

This endpoint is intended for polling the current policy enforcement state and does not initiate compliance evaluation or configuration deployment. Clients should ensure the device has completed enrollment and reported host details before using this endpoint.

### 2.1.4 Intune Service Endpoint Discovery

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

1. **Filter by Capability**: The client MUST parse the `"value"` array and extract service objects based on their `capability` field:
   - `LinuxEnrollmentService`
   - `LinuxDeviceCheckinService`

2. **Record URIs**: For each relevant service, the client MUST record the following:
   - `uri`: Used for subsequent service invocation.

3. **Cache Results Appropriately**: Clients SHOULD cache the discovered endpoints in memory for the lifetime of the session or until invalidated. Service discovery SHOULD be repeated each time a checkin is performed.

If the service does not return the expected capabilities, the client MUST treat the response as non-actionable and fail gracefully.

## 2.1.5 policies

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

__accountId__: Unknown.

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

##### 2.1.5.1.3 Processing Details

Upon receiving a `GET` request to the `policies` endpoint, the LinuxDeviceCheckinService performs the following actions:

1. **Authorization Validation**: Verifies that the bearer token is valid and scoped to the Microsoft Intune Company Portal Application.

2. **Policy Retrieval**: Fetches the current policies assigned to the device. If no policies are available, an empty `policies` array is returned.

3. **Response Construction**: Constructs a JSON object containing the device's policy details, including settings and their values.

4. **Error Handling**: If the request is unauthorized or the token is invalid, an HTTP 401 Unauthorized status is returned.

# 3 Protocol Examples

## 3.1 Intune Linux Enrollment

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

### Request body

In the request body, supply a JSON representation of a Linux enrollment
request, as specified in [section 2.1.1.1.1](#enroll-request-body).

### Response

If successful, this method returns a 200 response code and a signed
certificate in the response body, as specified in
[section 2.1.1.1.2](#enroll-response-body).

### Example

The following example shows a request to the Linux Enrollment Service endpoint
to enroll the host for policy enforcement ([section 2.1.1.1.1](#enroll-request-body))
and the response ([section 2.1.1.1.2](#enroll-response-body)).

### Request

Here is an example of the request.

<blockquote>
<strong>Note:</strong> The request object shown here is shortened for
readability.
</blockquote>

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com//TrafficGateway/TrafficRoutingService/LinuxMDM/LinuxEnrollmentService/enroll?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "AppVersion": "1.2405.17",
  "DeviceName": "MyPC",
  "CertificateSigningRequest": "MIICd...LWH31"
}
</code></pre>

### Response

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

## 3.2 Intune Linux Device Details

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

### Request body

In the request body, supply a JSON representation of a Linux device details
request, as specified in [section 2.1.2.1.1](#details-request-body).

### Response

If successful, this method returns a 200 response code and a device friendly
name in the response body, as specified in
[section 2.1.2.1.2](#details-response-body).

### Example

The following example shows a request to the Linux Device Checkin Service endpoint
to supply device details for the host ([section 2.1.2.1.1](#details-request-body))
and the response ([section 2.1.2.1.2](#details-response-body)).

### Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService/LinuxMdm/LinuxDeviceCheckinService/details?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "DeviceId": "8077ec2c-abca-46d2-9621-a0f06a460f96",
  "DeviceName": "openSUSE-Laptop",
  "Manufacturer": "Lenovo",
  "OSDistribution": "openSUSE Tumbleweed",
  "OSVersion": "20241211"
}
</code></pre>

### Response

Here is an example of the response.

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
  "deviceFriendlyName": ""
}
</code></pre>

## 3.3 Intune Linux Policy Status

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

### Request body

In the request body, supply a JSON representation of a Linux policy status
request, as specified in [section 2.1.3.1.1](#status-request-body).

### Response

If successful, this method returns a 200 response code and a list of policy statuses
in the response body, as specified in [section 2.1.3.1.2](#status-response-body).

### Example

The following example shows a request to the Linux Device Checkin Service endpoint
to check the policy status for the host ([section 2.1.3.1.1](#status-request-body))
and the response ([section 2.1.3.1.2](#status-response-body)).

### Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">POST https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService/LinuxMdm/LinuxDeviceCheckinService/status?api-version=1.0&client-version=1.2405.17
Content-type: application/json

{
  "DeviceId": "8077ec2c-abca-46d2-9621-a0f06a460f96"
}
</code></pre>

### Response

Here is an example of the response.

<pre class="has-inner-focus">
<code class="lang-json">HTTP/1.1 200
Content-type: application/json

{
  "policyStatuses": []
}
</code></pre>

## 3.4 Intune Service Endpoint Discovery

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

### Request body

Empty.

### Response

If successful, this method returns a 200 response code a json list of
service endpoints, as specified in
[section 2.1.4.1.2](#service-endpoint-discovery-response-body).

### Example

The following example shows a response from the Microsoft Graph for Intune
service endpoints ([section 2.1.4.1.2](#service-endpoint-discovery-response-body)).

### Request

Empty.

### Response

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

## 3.5 Intune Linux Policies

Retrieve device policies for the Linux Intune enrolled device.

### HTTP Request

<pre class="has-inner-focus">
<code class="lang-http"><span>
POST {LinuxDeviceCheckinServiceURI}/policies/{intune-device-id}?api-version=1.0&client-version=1.2405.17
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

### Request body

Empty.

### Response

If successful, this method returns a 200 response code and a list of policies, as specified in
[section 2.1.5.1.2](#policies-response-body).

### Example

The following example shows a request to the Linux Device Checkin Service endpoint
to request policies for the host ([section 2.1.5.1.1](#policies-request-body))
and the response ([section 2.1.5.1.2](#policies-response-body)).

### Request

Here is an example of the request.

<pre class="has-inner-focus">
<code class="lang-json">GET https://fef.msua08.manage.microsoft.com/TrafficGateway/TrafficRoutingService/LinuxMdm/LinuxDeviceCheckinService/policies/e82e80fe-1654-4766-848e-5e4db9a941ca?api-version=1.0&client-version=1.2405.17
</code></pre>

### Response

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
