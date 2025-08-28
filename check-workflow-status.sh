#!/bin/bash

# 🚦 GitHub Actions Workflow Status Checker
# Helps avoid Terraform state conflicts by checking running workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed"
    print_status "Install from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub CLI"
    print_status "Run: gh auth login"
    exit 1
fi

print_status "🔍 Checking GitHub Actions workflow status..."

# Get running workflows
RUNNING_WORKFLOWS=$(gh run list --limit 10 --json status,name,headSha,createdAt | jq -r '.[] | select(.status == "in_progress") | "\(.name) - \(.headSha[0:7]) - \(.createdAt)"')

if [ -z "$RUNNING_WORKFLOWS" ]; then
    print_success "No workflows currently running"
    print_success "✅ Safe to run Terraform commands"
else
    print_warning "⚠️  Running workflows detected:"
    echo "$RUNNING_WORKFLOWS" | while read -r workflow; do
        echo "   🔄 $workflow"
    done

    # Check for Terraform-related workflows
    TERRAFORM_WORKFLOWS=$(echo "$RUNNING_WORKFLOWS" | grep -i "terraform\|infrastructure\|quality\|security" || true)

    if [ -n "$TERRAFORM_WORKFLOWS" ]; then
        print_error "🚫 Terraform-related workflows are running!"
        print_error "This will cause state conflicts"
        echo ""
        print_status "💡 Options:"
        echo "   1. Wait for running workflows to complete"
        echo "   2. Cancel running workflows if they're stuck"
        echo "   3. Use: gh run cancel <run-id>"
        echo ""
        exit 1
    else
        print_warning "Non-Terraform workflows running - should be safe"
        print_status "Monitor them to ensure they complete"
    fi
fi

print_success "🎉 Ready to proceed with Terraform operations!"
print_status "Current concurrency controls are active to prevent conflicts"
