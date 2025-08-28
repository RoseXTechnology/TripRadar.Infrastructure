terraform {
  # NOTE: Do not configure a backend in child modules.
  # Backend blocks are only valid in the root module. This file
  # previously set a local backend and caused Terraform to warn:
  # "Backend configuration ignored".
  #
  # Intentionally left without a backend configuration.
}
