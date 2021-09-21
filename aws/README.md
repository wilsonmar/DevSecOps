# aws-terraform.md

This article describes steps to create a JAM website using Terraform provisioning in the AWS cloud (rather than a hosting account).
Policy-as-code TFSec.

## The work involved

1. Get a GitHub account (if you don't already have one).
1. <a href="#CreateRepo">Create a repository on GitHub</a> (with basic .gitignore, README.md, LICENSE) based on a Terraform template with an example for multiple enviornments and secure storage of secrets.

1. Instead of an index.html, OPTIONALLY: Define content (markdown files) and generate static HTML (using Gatzby, Jekyll, etc.).

   ### Domain Registrar

1. <a href="#GetDomain">Get a domain name from a Domain Registrar</a> (xyz for $.99, GoDaddy, etc.)

   Your enterprise may want you to use a sub-domain.

   ### Terraform

1. <a href="#TFC">Get a Terraform Cloud account</a>

1. <a href="#Variables">Specify global Terraform variables</a>.

   ### AWS

1. <a href="#AWS_Acct">Get an AWS IAM account</a> and configure the <tt>~/.aws/credentials</tt> folder with AWS Access Key, the AWS Access Secret, default AWS Region, JSON.
1. Get static content (index.html, images, etc.) in Amazon S3 buckets.
1. <a href="#.github">Specify domain name in CI/CD automation</a> (GitHub Actions: .github/workflows/ci.yml)
1. Define Terraform
1. Define Policy-as-Code (Rego programs based on examples from TFSec by Aqua Security)
1. Test run to DNS host name.

<hr />

## Terraform

1. Get an <strong>SSL/TLS certificate</strong> for HTTPS port 443 (using AWS Certificate Manager)
1. Get DNS to point to CloudFront (using Amazon Route 53)
1. Get Domain Registrar to pont the domain name to AWS Nameservers

1. Add tests using Terratest
1. Add contribution guidelines & Issue templates


<hr />


<a name="CreateRepo"></a>

## Create a repository on GitHub

1. OPTIONAL: Setup tag at the top of README.md

   https://shields.io/

   For "build: passing" ![ci](https://img.shields.io/github/workflow/status/worldofprasanna/terraform-aws-staticwebsite/CI_Pipeline)
   

   ![git-tag](https://img.shields.io/github/v/tag/worldofprasanna/terraform-aws-staticwebsite)
   ![license](https://img.shields.io/github/license/worldofprasanna/terraform-aws-staticwebsite)
   [![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)
   [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)


For reusability

* README.md</strong></tt>

   

* LICENSE</strong></tt>

* <tt><strong>.gitignore</strong></tt>

   <pre>.DS_Store
.terraform/
plan.out
terraform.tfstate
terraform.tfstate.backup
   </pre>

* .husky</strong></tt>

* .github</strong></tt> stores Workflow yml files which control jobs run in GitHub Actions


https://github.com/wilsonmar/terraform-aws-staticwebsite/blob/master/variables.tf


<a name="TFC"></a>

## Get a Terraform Cloud account

See https://learn.hashicorp.com/tutorials/terraform/cloud-sign-up?in=terraform/cloud-get-started

1. On your local machine, define a TFC folder.
1. Install local terraform.
1. Login at https://app.terraform.io/signup/account
1. In the pop-up browser page, copy the API token.
1. Paste the token.

   Welcome to Terraform Cloud!

1. see Documentation: terraform.io/docs/cloud  

   <pre>git clone https://github.com/hashicorp/tfc-getting-started.git --depth 1
   </pre>

   <pre>Cloning into 'tfc-getting-started'...
remote: Enumerating objects: 10, done.
remote: Counting objects: 100% (10/10), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 10 (delta 0), reused 7 (delta 0), pack-reused 0
Receiving objects: 100% (10/10), 11.00 KiB | 160.00 KiB/s, done.
   </pre>

1. Get in:

   <pre>cd tfc-getting-started
   </pre>

1. See what we get

   <pre>ls
   </pre>

   <pre>LICENSE     README.md   backend.tf  main.tf     provider.tf scripts</pre>

1. Get in:

   <pre>cd scripts/setup.sh
   </pre>

   <pre>--------------------------------------------------------------------------
Getting Started with Terraform Cloud
-------------------------------------------------------------------------
&nbsp;
Terraform Cloud offers secure, easy-to-use remote state management and allows
you to run Terraform remotely in a controlled environment. Terraform Cloud runs
can be performed on demand or triggered automatically by various events.
&nbsp;
This script will set up everything you need to get started. You'll be
applying some example infrastructure - for free - in less than a minute.
&nbsp;
First, we'll do some setup and configure Terraform to use Terraform Cloud.
Press any key to continue (ctrl-c to quit):
   </pre>

1. Press Enter to:

   <pre>Creating an organization and workspace...
Writing remote backend configuration to backend.tf...
&nbsp;
========================================================================
&nbsp;
Ready to go; the example configuration is set up to use Terraform Cloud!
&nbsp;
An example workspace named 'getting-started' was created for you.
You can view this workspace in the Terraform Cloud UI here:
https://app.terraform.io/app/example-org-e2a203/workspaces/getting-started
&nbsp;
Next, we'll run 'terraform init' to initialize the backend and providers:
   </pre>   	

1. Press Enter to: (terraform plan).
1. Press Enter to: (terraform plan).
1. <tt>terraform apply -auto-approve</tt>

   <pre>You now have:
&nbsp;
  * Workspaces for organizing your infrastructure. Terraform Cloud manages
    infrastructure collections with workspaces instead of directories. You
    can view your workspace here:
    https://app.terraform.io/app/example-org-e2a203/workspaces/getting-started
  * Remote state management, with the ability to share outputs across
    workspaces. We've set up state management for you in your current
    workspace, and you can reference state from other workspaces using
    the 'terraform_remote_state' data source.
  * Much more!
&nbsp;
To see the mock infrastructure you just provisioned and continue exploring
Terraform Cloud, visit:
https://app.terraform.io/fake-web-services
   </pre>

1. <a target="_blank" href="https://app.terraform.io/fake-web-services">https://app.terraform.io/fake-web-services</a> for "Your example configuration".

1. Play around by adding to <strong>main.tf</strong> resources: Server 3 and 4.

1. Re-run <tt>terraform apply</tt>.

   PROTIP: If forget to add <tt>\-\-auto-approve<tt>, you'll be prompted to manually type "yes":

   <pre>Do you want to perform these actions in workspace "getting-started"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
&nbsp;
  Enter a value:
    </pre>

1. The diagram at https://app.terraform.io/fake-web-services will be updated.

1. REMEMBER: Destroy resources so it doesn't accrue charges:

   <pre><strong>terraform destroy --auto-approve</strong></pre>


1. generate a plan for every pull requests
1. apply the configuration when you update the main branch


   <a name"#AWS_Acct"></a>

   ## Get an AWS IAM account

   Per <a target="_blank" href="https://registry.terraform.io/providers/hashicorp/aws/latest/docs">DOCS</a>:

1. Since enterprises provide Access Keys of 12 hours or less, copy the variables and paste in Terminal:

   <pre>export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_DEFAULT_REGION="us-west-2"
   </pre>

   https://github.com/wilsonmar/terraform-aws-staticwebsite/blob/master/.github/workflows/ci.yml

   To authenticate using <a target="_blank" href="
   https://learn.hashicorp.com/tutorials/terraform/aws-assumerole?_ga=2.204673497.811779648.1631929958-376546056.1629215321">Use AssumeRole to Provision AWS Resources Across Accounts</a>


<a name="Secrets"></a>

## Secrets

https://github.com/wilsonmar/terraform-aws-staticwebsite/blob/master/variables.tf


<a name"GetDomain"></a>

## Choose a Domain Registrar and choose a domain name

The first domain name in history was <a target="_blank" href="https://www.computerweekly.com/news/1280090622/The-first-ever-20-domain-names-registered">Symbolics.com, registered on March 15, 1985</a>. 

A domain name is what visitors type into their internet browser address bar to reach your website.

Because of the typing involved, the smaller number of letters, the more valuable the name: cars.com sold for $872 million because it's easy to remember.

".com" is a TLD (Top-level-Domain) extension. There are also ".info" and ".xyz".

"Free" domain names are offered by hosting companies.
   * yourdomainname.github.io
   * yourdomainname.wordpress.com
   * yourdomainname.wix.com
   * yourdomainname.weebly.com
   <br /><br />

"Free" domain names are offered for a year or with a hosting plan by some companies:
   * GoDaddy.com is the largest
   <br /><br />

Add domain ID protection, so your name and contact info is not exposed.


<a name=".github"></a>

## Specify Your Domain Name in Terraform Variables

In <tt>vars.tf</tt> add

   <pre>variable "site_name" 
description = "The full DNS domain for the site."
}
   </pre>

   <tt>var.site_name" is referenced in <tt>ssl_cert_req.sh</tt>.


.github


<a name="CreateRepo"></a>

## One step

In Terraform modules, values for <tt>source</tt> variable define modules pre-defined at the Terraform.io registry. For example, "worldofprasanna/staticwebsite/aws" would be 

   <ul><a target="_blank" href="https://registry.terraform.io/modules/worldofprasanna/staticwebsite/aws/latest">https://registry.terraform.io/modules/worldofprasanna/staticwebsite/aws/latest</a>
   </ul>


<pre># Replace yourdomain.com
module "staticwebsite" {
  source  = "worldofprasanna/staticwebsite/aws"
  version = "1.0.0"
  domain = "yourdomain.com"
}
# To create the resource,
terraform apply  
# To upload the static assests,
aws s3 sync build/ s3://yourdomain.com
   </pre>


   <pre>cd examples/simple
terraform init
terraform plan -out plan.out
terraform apply plan.out
   </pre>

## References

https://github.com/ned1313/Implementing-Terraform-on-AWS/
based on https://app.pluralsight.com/library/courses/implementing-terraform-aws/table-of-contents
by Ned Ballavance

https://medium.com/modern-stack/5-minute-static-ssl-website-in-aws-with-terraform-76819a12d412
on https://github.com/divgo/terraform/tree/master/aws_ssl_static_website

https://blog.francium.tech/how-to-serve-your-website-from-aws-s3-using-terraform-94dfd16324bf
on https://github.com/worldofprasanna/terraform-aws-staticwebsite

https://learn.hashicorp.com/tutorials/terraform/cloudflare-static-website?in=terraform/aws

https://aws.amazon.com/blogs/developer/introducing-the-cloud-development-kit-for-terraform-preview/

https://github.com/marketplace/actions/hashicorp-setup-terraform
GitHub.com Marketplace: Hashicorp Setup Terraform
