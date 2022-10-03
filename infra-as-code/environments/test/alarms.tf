resource "aws_cloudwatch_metric_alarm" "target_response_time" {
    alarm_name          = "${replace(aws_lb_target_group.front_end.arn_suffix,"/(targetgroup/)|(/\\w+$)/","")}-Response-Time"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = var.evaluation_period
    metric_name         = "TargetResponseTime"
    namespace           = "AWS/ApplicationELB"
    period              = "${lookup(var.time_response_thresholds, "period")}"
    statistic           = "${lookup(var.time_response_thresholds, "statistic")}"
    threshold           = "${lookup(var.time_response_thresholds, "threshold")}"

    dimensions = {
        LoadBalancer = "${aws_lb.front_end.arn_suffix}"
        TargetGroup  = "${aws_lb_target_group.front_end.arn_suffix}"
    }

    alarm_description  = "Trigger an alert when response time in ${aws_lb_target_group.front_end.arn_suffix} goes high"
    treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "target_healthy_count_applications" {
    alarm_name          = "Applications-Healthy-Count"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = var.evaluation_period
    threshold           = "2"
    alarm_description   = "Trigger an alert when the applications has 3 or more unhealthy tasks."
    treat_missing_data  = "breaching"

    metric_query {
        id          = "e1"
        expression  = "m1+m2"
        label       = "Unhealthy Nodes"
        return_data = "true"
    }

    metric_query {
        id = "m1"

        metric {
            metric_name         = "HealthyHostCount"
            namespace           = "AWS/ApplicationELB"
            period              = var.statistic_period
            stat                = "Average"

            dimensions = {
                LoadBalancer = "${aws_lb.front_end.arn_suffix}"
                TargetGroup  = "${aws_lb_target_group.front_end.arn_suffix}"
            }
        }
    }

    metric_query {
        id = "m2"

        metric {
            metric_name         = "HealthyHostCount"
            namespace           = "AWS/ApplicationELB"
            period              = var.statistic_period
            stat                = "Average"

            dimensions = {
                LoadBalancer = "${aws_lb.back_end.arn_suffix}"
                TargetGroup  = "${aws_lb_target_group.back_end.arn_suffix}"
            }
        }
    }
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name                = "web-app-error-rate"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_period
  threshold                 = "10"
  alarm_description         = "Request error rate has exceeded 10%"
  insufficient_data_actions = []

  metric_query {
    id          = "e1"
    expression  = "(m2+m3)/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = var.statistic_period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${aws_lb.front_end.arn_suffix}"
        TargetGroup  = "${aws_lb_target_group.front_end.arn_suffix}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = var.statistic_period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${aws_lb.front_end.arn_suffix}"
        TargetGroup  = "${aws_lb_target_group.front_end.arn_suffix}"
      }
    }
  }

  metric_query {
    id = "m3"

    metric {
      metric_name = "HTTPCode_ELB_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = var.statistic_period
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${aws_lb.front_end.arn_suffix}"
        TargetGroup  = "${aws_lb_target_group.front_end.arn_suffix}"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_too_high" {
    alarm_name          = "rds-highCPUUtilization"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = var.evaluation_period
    metric_name         = "CPUUtilization"
    namespace           = "AWS/RDS"
    period              = var.statistic_period
    statistic           = "Average"
    threshold           = "80"
    alarm_description   = "Average database CPU utilization is too high."

    dimensions = {
        DBInstanceIdentifier = aws_db_instance.rds_demo.id
    }
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_free_storage_space_too_low" {
    alarm_name          = "rds-lowFreeStorageSpace"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = var.evaluation_period
    metric_name         = "FreeStorageSpace"
    namespace           = "AWS/RDS"
    period              = var.statistic_period
    statistic           = "Average"
    threshold           = "1000000000" # 1GB
    alarm_description   = "Average database free storage space is too low and may fill up soon."

    dimensions = {
        DBInstanceIdentifier = aws_db_instance.rds_demo.id
    }
}
