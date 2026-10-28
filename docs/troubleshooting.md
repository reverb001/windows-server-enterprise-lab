# Infrastructure Troubleshooting and Lessons Learned

## Overview

This document describes technical issues encountered while configuring and testing a Windows Server enterprise infrastructure lab.

The environment consists of four Hyper-V virtual machines running Active Directory Domain Services, DNS, DHCP, Group Policy, SMB file sharing, and a Windows-based application server.

The examples demonstrate practical troubleshooting techniques using PowerShell, Windows administrative tools, and network diagnostics.

---

# Case Study 1: Group Policy Not Targeting the Intended Users

## Environment

- **Domain Controller:** DC01
- **Operating System:** Windows Server 2022
- **Domain:** corp.example.test
- **Client:** CLIENT01 (Windows 11)
- **Technology:** Active Directory and Group Policy

## Problem

A Group Policy Object was configured to restrict access to the Windows Control Panel.

The policy was initially named `Workstation - Disable Control Panel` and linked to the `Workstations` organisational unit (OU).

However, the restriction was configured under **User Configuration**, rather than Computer Configuration.

Because the policy was linked to an OU containing computer accounts instead of the intended user accounts, its targeting did not match the configuration.

## Investigation

Reviewed the Group Policy configuration and identified the distinction between user and computer policy processing.

Group Policy settings generally apply according to the location of the relevant Active Directory objects:

- **Computer Configuration:** Applies to computer accounts.
- **User Configuration:** Applies to user accounts.

The lab's original GPO link targeted the workstation OU, while the restriction itself was a user-based setting.

## Resolution

The following changes were made:

1. Renamed the GPO to `User - Restrict Control Panel`.
2. Linked the policy to the `Sales` OU under `Company Users`.
3. Signed into CLIENT01 using the standard domain user `CORP\agarcia`.
4. Checked the resulting user policy application.

The following command was used to inspect applied user policies:

```powershell
gpresult /r /scope user
```

The output included:

```text
Applied Group Policy Objects
-----------------------------
User - Restrict Control Panel
```

This confirmed that the GPO was included in the user's applied policy results.

**Verification limitation:** The policy appeared in `gpresult`, but the Control Panel restriction itself was not separately confirmed through a functional test.

## Lessons Learned

- User and computer policies must be linked to appropriate Active Directory locations.
- Correct OU structure and policy targeting are essential for predictable Group Policy behaviour.
- `gpresult` provides a useful starting point for investigating policy application.
- Policy application and enforcement of an individual setting are separate verification steps.

---

# Case Study 2: Troubleshooting Application Server Connectivity

## Environment

- **Application Server:** APP01
- **Operating System:** Windows Server 2022
- **IP Address:** 192.168.50.30
- **Client:** CLIENT01
- **Client IP:** 192.168.50.100
- **Network:** LAB-NAT (192.168.50.0/24)
- **Web Server:** Apache HTTP Server 2.4.69
- **Application Stack:** Apache, PHP, MySQL

## Problem

CLIENT01 initially could not access the website hosted on APP01.

Initial connectivity testing also showed that ICMP ping requests to APP01 timed out.

The investigation focused on determining whether the problem involved:

- Network connectivity
- DNS resolution
- Windows Firewall
- Apache service availability
- HTTP access or application configuration

## Investigation

### 1. Test TCP Connectivity

From CLIENT01, tested TCP port 80 on APP01:

```powershell
Test-NetConnection 192.168.50.30 -Port 80 -InformationLevel Detailed
```

The result included:

```text
TcpTestSucceeded : True
```

This established that CLIENT01 could successfully establish a TCP connection to APP01 on port 80.

The successful TCP test indicated that basic HTTP network connectivity was available.

### 2. Test DNS Resolution

From CLIENT01, tested name resolution:

```powershell
Resolve-DnsName APP01.corp.example.test
```

The domain DNS server returned:

```text
APP01.corp.example.test
192.168.50.30
```

This confirmed that DNS resolution was functioning correctly.

### 3. Verify Apache Availability

On APP01, confirmed that the Apache service was running and listening on TCP port 80.

Tested the local web server using PowerShell:

```powershell
Invoke-WebRequest http://localhost -UseBasicParsing |
    Select-Object StatusCode
```

Result:

```text
StatusCode
----------
200
```

HTTP status code `200` confirmed that Apache successfully served a request locally.

### 4. Review Windows Firewall

Verified that APP01:

- Was using the `DomainAuthenticated` network profile.
- Had Windows Firewall enabled.
- Had an enabled inbound firewall rule allowing TCP port 80.

This helped establish that the expected HTTP traffic was permitted.

### 5. Investigate Ping Failure

ICMP ping requests from CLIENT01 continued to time out during the investigation.

However, TCP port 80 connectivity was successful.

This demonstrated an important troubleshooting distinction:

**A failed ping does not necessarily indicate that a server or application is unreachable.**

ICMP echo requests can be blocked independently of TCP connections.

The precise reason for the ICMP timeout was not established.

## Outcome

Following the investigation, the website became accessible from CLIENT01.

The following components were verified:

| Component | Result |
|---|---|
| DNS resolution | Successful |
| TCP port 80 connectivity | Successful |
| Apache service | Running |
| Local HTTP request | HTTP 200 |
| Windows Firewall HTTP rule | Enabled |
| Website access from CLIENT01 | Successful |
| ICMP ping | Timed out during testing |

The investigation confirmed that the underlying network and web server services were functioning.

**Root cause:** The exact cause of the initial browser access failure was not conclusively identified.

## Lessons Learned

- Troubleshoot connectivity systematically rather than assuming a failed ping means a server is offline.
- Test the specific application port using `Test-NetConnection`.
- Verify DNS resolution separately from IP connectivity.
- Check whether the application service is running and listening on the expected port.
- Test a web service locally before investigating remote access.
- Distinguish confirmed findings from suspected causes.

---

# Troubleshooting Tools Used

| Tool | Purpose |
|---|---|
| `gpresult` | Verify applied Group Policy Objects |
| `Test-NetConnection` | Test TCP connectivity to a specific port |
| `Resolve-DnsName` | Validate DNS name resolution |
| `Invoke-WebRequest` | Test HTTP responses |
| `Get-NetFirewallRule` | Inspect Windows Firewall rules |
| `Get-Service` | Check Windows service status |
| PowerShell | Perform infrastructure diagnostics and administrative tasks |

## Summary

These exercises reinforced the importance of structured troubleshooting in Windows enterprise environments.

Rather than making configuration changes without understanding the problem, the approach was to:

1. Identify the reported symptom.
2. Test the relevant infrastructure components.
3. Narrow down potential causes using diagnostic results.
4. Correct identified configuration issues where appropriate.
5. Verify the outcome.
6. Document findings and remaining uncertainties.

The experience provided practical exposure to Active Directory, Group Policy processing, DNS, TCP/IP connectivity, Windows Firewall, and application server administration.
