/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = var.project_id
  region  = var.region
}
terraform {
  required_providers {
    google = {
      version = "~> 4.0"
    }
  }
}

/**
 * Task 1: Add Network ("network")
 * - source: "terraform-google-modules/network/google"
 * - version: "~> 4.1.0"
 * - project_id: module.project_iam_bindings.projects[0]
 * - network_name: "lab03-vpc"
 * - routing_mode: "GLOBAL"
 * - subnets:
 *   - subnet_name: "lab03-subnet-01"
 *   - subnet_ip: "10.0.10.0/24"
 *   - subnet_region: var.region
 *
 * Reference - https://github.com/terraform-google-modules/terraform-google-network
 *
 */
module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 6.0"

    project_id   = "core-photon-372612"
    network_name = "example-vpc"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-west1"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "This subnet has a description"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-west1"
            subnet_flow_logs          = "true"
            subnet_flow_logs_interval = "INTERVAL_10_MIN"
            subnet_flow_logs_sampling = 0.7
            subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
        }
    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]

        subnet-02 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
        {
            name                   = "app-proxy"
            description            = "route through proxy to reach app"
            destination_range      = "10.50.10.0/24"
            tags                   = "app-proxy"
            next_hop_instance      = "app-proxy-instance"
            next_hop_instance_zone = "us-west1-a"
        },
    ]
}

/**
 * Task 2: Add Cloud NAT Instance ("cloud_nat")
 * - source: "terraform-google-modules/cloud-nat/google"
 * - version: "~> 2.1.0"
 * - project_id: module.project_iam_bindings.projects[0]
 * - region: var.region
 * - create_router: true
 * - router: "lab03-router"
 * - network: refer to network_name created in Task 1 - module.network.network_name
 *
 * Reference - https://github.com/terraform-google-modules/terraform-google-cloud-nat
 *
 */
module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
}
