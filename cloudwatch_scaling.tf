
# CloudWatch Metric Alarms to monitor CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "nginx-cpu-utilization-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 20
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_scale_down" {
  alarm_name          = "nginx-cpu-utilization-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 10
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.nginx.name
  }
}

# Auto Scaling policy for scaling up
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "nginx-scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.nginx.name
}

# Auto Scaling policy for scaling down
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "nginx-scale-down-policy"
  scaling_adjustment     = -1                               # Remove one instance
  adjustment_type        = "ChangeInCapacity"               # Type of adjustment
  cooldown               = 300                              # Cooldown period in seconds
  autoscaling_group_name = aws_autoscaling_group.nginx.name # Target the nginx Auto Scaling Group
}