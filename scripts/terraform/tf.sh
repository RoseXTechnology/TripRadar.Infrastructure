#!/bin/bash

# Terraform Helper Script for TripRadar Infrastructure (Cross-platform)
# This script works on Linux, macOS, and Windows (with Git Bash)
# Designed for GitHub Actions and local development

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to get script directory (cross-platform)
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        # Get the directory of the script
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        # Fallback for environments where BASH_SOURCE is not available
        echo "$(pwd)"
    fi
}

# Function to check if running in GitHub Actions
is_github_actions() {
    [[ -n "${GITHUB_ACTIONS}" ]]
}

# Function to get repository root
get_repo_root() {
    local script_dir=$(get_script_dir)

    # If running in GitHub Actions, workspace is set
    if is_github_actions; then
        echo "${GITHUB_WORKSPACE:-$script_dir}"
    else
        # Go up from infra/terraform to repository root
        echo "$(cd "$script_dir/../../../.." 2>/dev/null && pwd || echo "$script_dir")"
    fi
}

# Validate environment parameter
validate_environment() {
    local env=$1
    case $env in
        dev|staging|prod)
            return 0
            ;;
        *)
            print_error "Invalid environment: $env. Must be dev, staging, or prod."
            exit 1
            ;;
    esac
}

# Validate action parameter
validate_action() {
    local action=$1
    case $action in
        plan|apply|destroy|init|validate|fmt|import|output)
            return 0
            ;;
        *)
            print_error "Invalid action: $action. Must be plan, apply, destroy, init, validate, fmt, import, or output."
            exit 1
            ;;
    esac
}

# Main script
main() {
    # Parse command line arguments
    local environment=""
    local action=""
    local auto_approve=false
    local compact_warnings=false
    local additional_args=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            -a|--action)
                action="$2"
                shift 2
                ;;
            --auto-approve)
                auto_approve=true
                shift
                ;;
            --compact-warnings)
                compact_warnings=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                # Collect additional arguments for terraform
                additional_args="$additional_args $1"
                shift
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$environment" ]]; then
        print_error "Environment is required. Use -e or --environment."
        show_help
        exit 1
    fi

    if [[ -z "$action" ]]; then
        print_error "Action is required. Use -a or --action."
        show_help
        exit 1
    fi

    validate_environment "$environment"
    validate_action "$action"

    # Get paths
    local repo_root=$(get_repo_root)
    local env_path="$repo_root/infra/terraform/environments/$environment/app"
    local tfvars_path="$repo_root/infra/terraform/environments/$environment/terraform.tfvars"

    print_status "Repository root: $repo_root"
    print_status "Environment path: $env_path"

    # Check if paths exist
    if [[ ! -d "$env_path" ]]; then
        print_error "Environment directory not found: $env_path"
        exit 1
    fi

    if [[ ! -f "$tfvars_path" && "$action" != "fmt" && "$action" != "validate" ]]; then
        print_error "Terraform variables file not found: $tfvars_path"
        exit 1
    fi

    # Navigate to environment directory
    print_status "Navigating to environment: $environment"
    cd "$env_path"

    # Build terraform command
    local tf_command="terraform $action"

    # For certain actions, add var-file (but not needed with auto.tfvars!)
    # The auto.tfvars file will be automatically loaded

    # Add flags
    if [[ "$auto_approve" == true && "$action" == "apply" ]]; then
        tf_command="$tf_command -auto-approve"
    fi

    if [[ "$compact_warnings" == true ]]; then
        tf_command="$tf_command -compact-warnings"
    fi

    # Add any additional arguments
    if [[ -n "$additional_args" ]]; then
        tf_command="$tf_command $additional_args"
    fi

    # Display command
    print_status "Executing: $tf_command"
    print_status "In directory: $(pwd)"

    # Execute command
    if eval "$tf_command"; then
        print_success "Command completed successfully!"
    else
        print_error "Command failed with exit code $?"
        exit 1
    fi
}

# Function to show help
show_help() {
    cat << EOF
Terraform Helper Script for TripRadar Infrastructure

USAGE:
    ./tf.sh -e ENVIRONMENT -a ACTION [OPTIONS]

REQUIRED ARGUMENTS:
    -e, --environment ENVIRONMENT    Environment (dev, staging, prod)
    -a, --action ACTION              Terraform action (plan, apply, destroy, init, validate, fmt, import, output)

OPTIONAL ARGUMENTS:
    --auto-approve                   Automatically approve apply/destroy operations
    --compact-warnings              Use compact warnings format
    -h, --help                      Show this help message

EXAMPLES:
    # Development environment
    ./tf.sh -e dev -a plan
    ./tf.sh -e dev -a apply --auto-approve
    ./tf.sh -e dev -a destroy

    # Staging environment
    ./tf.sh -e staging -a plan

    # Production environment
    ./tf.sh -e prod -a validate

GITHUB ACTIONS:
    This script is designed to work in GitHub Actions. The auto.tfvars files
    will be automatically loaded by Terraform without needing -var-file flags.

EOF
}

# Run main function with all arguments
main "$@"
