resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  lb_target_group_arn    = aws_lb_target_group.ecs_tg.arn
}
