# Terraform Lifecycle Rules - Complete Guide

## Overview
Lifecycle rules are meta-arguments that control how Terraform manages resource creation, updates, and deletion behavior.

## Core Lifecycle Rules - ALL POSSIBILITIES

### 1. create_before_destroy

#### TRUE (Enabled)
```hcl
lifecycle {
  create_before_destroy = true
}
```
- **Behavior**: Creates new resource BEFORE destroying old one
- **Result**: Zero downtime during replacement
- **Risk**: May cause resource conflicts or dependency cycles
- **Use When**: High availability is critical

#### FALSE (Disabled - Default)
```hcl
lifecycle {
  create_before_destroy = false
}
# OR simply omit it (default behavior)
lifecycle {
  # other rules only
}
```
- **Behavior**: Destroys old resource BEFORE creating new one
- **Result**: Potential downtime during replacement
- **Benefit**: No resource conflicts, cleaner replacement
- **Use When**: Downtime is acceptable or resources conflict

---

### 2. prevent_destroy

#### TRUE (Protection Enabled)
```hcl
lifecycle {
  prevent_destroy = true
}
```
- **Behavior**: Blocks `terraform destroy` and `terraform apply` that would destroy
- **Result**: Resource cannot be destroyed via Terraform
- **Override**: Use `-replace` flag or remove rule first
- **Use When**: Critical production resources

#### FALSE (No Protection - Default)
```hcl
lifecycle {
  prevent_destroy = false
}
# OR simply omit it (default behavior)
lifecycle {
  # other rules only
}
```
- **Behavior**: Normal destroy operations allowed
- **Result**: Resource can be destroyed normally
- **Use When**: Development/testing or non-critical resources

---

### 3. ignore_changes - ALL VARIATIONS

#### Ignore Specific Attributes
```hcl
lifecycle {
  ignore_changes = [tags]
}
```

#### Ignore Multiple Attributes
```hcl
lifecycle {
  ignore_changes = [
    tags,
    ami,
    user_data,
    security_groups
  ]
}
```

#### Ignore Nested Attributes
```hcl
lifecycle {
  ignore_changes = [
    tags["Environment"],
    tags["LastModified"],
    metadata["annotations"]
  ]
}
```

#### Ignore ALL Changes
```hcl
lifecycle {
  ignore_changes = [all]
}
```
- **Behavior**: Ignores ALL attribute changes
- **Result**: Resource becomes "read-only" to Terraform
- **Risk**: Terraform state becomes out of sync
- **Use When**: Resource fully managed externally

#### Ignore NO Changes (Default)
```hcl
# Simply omit ignore_changes
lifecycle {
  # other rules only
}
```
- **Behavior**: Terraform manages all changes
- **Result**: Full Terraform control

---

### 4. replace_triggered_by - ALL VARIATIONS

#### Single Resource Reference
```hcl
lifecycle {
  replace_triggered_by = [
    aws_security_group.example.id
  ]
}
```

#### Multiple Resource References
```hcl
lifecycle {
  replace_triggered_by = [
    aws_security_group.web.id,
    aws_key_pair.deployer.id,
    aws_launch_template.app.latest_version
  ]
}
```

#### Resource Attribute References
```hcl
lifecycle {
  replace_triggered_by = [
    aws_launch_template.app.latest_version,
    aws_ami.custom.id,
    data.aws_subnet.selected.id
  ]
}
```

#### No Triggered Replacement (Default)
```hcl
# Simply omit replace_triggered_by
lifecycle {
  # other rules only
}
```
- **Behavior**: Normal dependency-based replacement only

---

## ALL POSSIBLE COMBINATIONS

### Maximum Protection
```hcl
lifecycle {
  prevent_destroy = true
  ignore_changes = [tags, user_data]
}
```

### Zero Downtime with Selective Ignoring
```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes = [tags["LastModified"]]
}
```

### Full External Management
```hcl
lifecycle {
  ignore_changes = [all]
  prevent_destroy = true
}
```

### Coordinated Replacement
```hcl
lifecycle {
  create_before_destroy = true
  replace_triggered_by = [
    aws_launch_template.app.latest_version
  ]
}
```

### All Rules Combined
```hcl
lifecycle {
  create_before_destroy = true
  prevent_destroy = false  # explicit false
  ignore_changes = [tags["Environment"]]
  replace_triggered_by = [
    aws_security_group.web.id
  ]
}
```

### No Lifecycle Rules (Default Behavior)
```hcl
# No lifecycle block = all default behaviors
resource "aws_instance" "example" {
  # configuration without lifecycle
}
```

## Practical Examples

### Database Protection
```hcl
resource "aws_db_instance" "prod" {
  allocated_storage = 20
  engine           = "mysql"
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [password]
  }
}
```

### Zero-Downtime EC2 Updates
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["LastModified"]
    ]
  }
}
```

### Launch Template with Multiple Rules
```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = "ami-12345678"
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      user_data,
      tags
    ]
  }
}
```

## Common Patterns

### 1. Production Database
```hcl
lifecycle {
  prevent_destroy = true
  ignore_changes = [password, tags["backup_window"]]
}
```

### 2. Auto-Scaling Resources
```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes = [desired_capacity, min_size, max_size]
}
```

### 3. Externally Managed Tags
```hcl
lifecycle {
  ignore_changes = [
    tags["Environment"],
    tags["Owner"],
    tags["CostCenter"]
  ]
}
```

## Best Practices

1. **Use create_before_destroy** for resources that need high availability
2. **Apply prevent_destroy** to critical infrastructure components
3. **Use ignore_changes** sparingly - only when necessary
4. **Combine rules** when needed for complex scenarios
5. **Document lifecycle decisions** in comments

## Important Notes

- Lifecycle rules apply to the entire resource, not individual attributes
- `prevent_destroy` only prevents `terraform destroy`, not manual deletion
- `ignore_changes = [all]` should be used cautiously
- Some lifecycle combinations may conflict - test thoroughly
- Lifecycle rules don't affect data sources, only resources

## Troubleshooting

### Common Issues:
- **Dependency cycles**: Often caused by `create_before_destroy`
- **Ignored changes still applying**: Check attribute names and syntax
- **Prevent destroy not working**: May be overridden by force flags

### Solutions:
- Use `terraform plan` to verify lifecycle behavior
- Check for typos in attribute names
- Review dependency graphs with `terraform graph`