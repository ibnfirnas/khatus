NR == 2 {
	percentage = $1
	sub("%$", "", percentage)
    print("disk_usage_percentage", percentage)
}
