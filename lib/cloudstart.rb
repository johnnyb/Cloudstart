class Cloudstart
	def self.setup_logging(opts = {})
		if opts[:debug]
			@@logfh = $stderr
			@@logappend = " 2>&1"
		else
			@@logfile = opts[:log] || "/var/log/cloudstart.log"
			@@logfh = File.open(@@logfile, "a")
			@@logappend = " > #{@@logfile} 2>&1"
		end
	end

	def self.start_cloud_server(opts)
		setup_logging(opts)

		setup_hostnames(opts[:hostnames])
		setup_symlinks(opts[:symlinks])
		run_commands(opts[:commands])
		wait_for_mounts(opts[:mounts])
	end

	def self.is_blank?(val)
		return true if val == nil
		return true if val == ""
	end

	def self.run_commands(cmds)
		cmds ||= []
		cmds.each do |cmd|
			successful = system("#{cmd} #{@@logappend}")
			unless successful
				@@logfh.puts "Error running command: #{cmd}"
			end
		end
	end

	def self.is_mounted?(mountpoint)
		# Kill trailing slash so it is not reported on
		mountpoint = mountpoint[0..-2] if mountpoint[-1..-1] == "/"
		results = `mount`;
		results.split(/\n/).each do |mntline|
			mntinfo = mntline.split(/\s+/)
			return true if mntinfo[2] == mountpoint
		end
	end

	def self.wait_for_mounts(mountlist)
		mountlist.each do |mntinfo|
			nextmount = false

	
			mntsource = is_blank?(mntinfo[:label]) ? mntinfo[:device] : "-L mntinfo[:label]"
			mntcmd = "mount #{mntinfo[:options]} #{mntsource} #{mntinfo[:location]} #{@@logappend}"

			if is_mounted?(mntinfo[:location])
				@@logfh.puts "Mount point already mounted! Will not run (skipping commands): #{mntcmd}"
			else
				while(! nextmount)
					@@logfh.puts "Attempting to run mount command: #{mntcmd}"
					system(mntcmd)
	
					if is_mounted?(mntinfo[:location])
						run_commands(mntinfo[:commands])
						nextmount = true
					else
						@@logfh.puts "Mount failed (wait for another try): #{mntcmd}"
						sleep 10
					end
				end
			end
		end
	end

	def self.append_hostlist(hhash, key, newval)
		@@logfh.puts "appending #{newval} to #{key}"
		val = hhash[key]
		if is_blank?(val)
			val = ""
		else
			val += "\t"
		end

		val += newval
		hhash[key] = val
	end

	def self.setup_hostnames(hosts)
		hosts ||= {}
		defined_hostnames = hosts.keys

		realhosts = {}

		## Keep host entries that are not being overwritten
		File.open("/etc/hosts") do |f|
			f.each do |line|
				unless line.match(/^\s*\#/)
					line.chomp!
					line.strip!
					vals = line.split(/\s+/)
					ip = vals.first
					curhosts = vals[1..-1]||[]
					curhosts.each do |h|
						unless defined_hostnames.include?(h)
							append_hostlist(realhosts, ip, h)
						end
					end
				end
			end
		end

		hosts.each do |hname, ip|
			append_hostlist(realhosts, ip, hname)
		end

		File.open("/etc/hosts", "w") do |f|
			f.write("# Autogenerated from Cloudstart - modifications will possibly be overwritten on reboot")
			realhosts.each do |ip, val|
				f.write("#{ip}\t#{val}\n")
			end
		end
	end

	def self.setup_symlinks(linkinfo)
		linkinfo ||= {}

		linkinfo.each do |dest, real_file|
			performlink = true
			if File.symlink?(dest)
				File.unlink(dest)
			else
				if File.exists?(dest)
					@@logfh.puts "Error: file exists: #{dest} "
					performlink = false
				end
			end

			if performlink
				begin
					res = File.symlink(real_file, dest)
				rescue
					@@logfh.puts "Error performing symlink: #{real_file} #{dest}"
				end
			end
		end		
	end
end