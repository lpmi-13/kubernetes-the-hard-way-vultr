# Prerequisites

## Vultr

This tutorial leverages [Vultr](https://www.vultr.com/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up. It would cost less then $2 for a 24 hour period that would take to complete this exercise.

> There is no free tier for Vultr. Make sure that you clean up the resource at the end of the activity to avoid incurring unwanted costs.

## Vulture CLI

### Install the Vultr CLI

Follow the Vultr CLI [documentation](https://github.com/vultr/vultr-cli) to install and configure the `vultr-cli` command line utility.

The current walkthrough was done with version 2.7.0

Verify the Vultr CLI version using:

```
vultr-cli version
```

### Set a Default Compute Region and Zone

This tutorial assumes a default compute region.

Go ahead and set a default compute region:

- you can see all the datacenters [here](https://www.vultr.com/features/datacenter-locations/), though that won't have the region id that you need for the API commands. For that, just run `vultr-cli regions list`, and you should get a list like below:

```
ID      CITY            COUNTRY         CONTINENT       OPTIONS
ams     Amsterdam       NL              Europe          [ddos_protection]
atl     Atlanta         US              North America   []
cdg     Paris           FR              Europe          [ddos_protection]
dfw     Dallas          US              North America   [ddos_protection]
ewr     New Jersey      US              North America   [ddos_protection block_storage]
fra     Frankfurt       DE              Europe          [ddos_protection]
icn     Seoul           KR              Asia            []
lax     Los Angeles     US              North America   [ddos_protection block_storage]
lhr     London          GB              Europe          [ddos_protection]
mia     Miami           US              North America   [ddos_protection]
nrt     Tokyo           JP              Asia            []
ord     Chicago         US              North America   [ddos_protection]
sea     Seattle         US              North America   [ddos_protection]
sgp     Singapore       SG              Asia            []
sjc     Silicon Valley  US              North America   [ddos_protection]
syd     Sydney          AU              Australia       []
yto     Toronto         CA              North America   []
======================================
TOTAL   NEXT PAGE       PREV PAGE
17
```

Choose one of those regions, and set it in your terminal:

```
export REGION=lhr
```

### configure the CLI tool to interact with your account

Once you've signed up for an account, navigate to https://my.vultr.com/settings/#settingsapi and you can enable API usage, for the account. It should automatically generate an access token, then you can set it in your terminal:

```
export VULTR_API_KEY=your_api_key
```

## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with `synchronize-panes` enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable `synchronize-panes`: `ctrl+b` then `shift :`. Then type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](02-client-tools.md)
