require 'pathname'

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      class Base

        def create_adapter
          # TODO need to make this cleaner before PR.  Regex for version match, and let's not pass in two empty strings for earlier versions...
          if @version.starts_with?("4.0") or @version.starts_with?("4.1") or @version.starts_with?("4.2")
            portcount = "--sataportcount"
            addaction = ""
            addtype = ""
          else
            portcount = "--portcount"
            addaction = "--add"
            addtype = "sata"
          end
          execute("storagectl", @uuid, "--name", "SATA Controller", portcount, "2", addaction, addtype )
        end

        def create_storage(location, size)
          execute("createhd", "--filename", location, "--size", "#{size}")
        end

        def attach_storage(location)
          execute("storageattach", @uuid, "--storagectl", "SATA Controller", "--port", "1", "--device", "0", "--type", "hdd", "--medium", "#{location}")
        end

        def detach_storage(location)
          if location and identical_files(read_persistent_storage(location), location)
            execute("storageattach", @uuid, "--storagectl", "SATA Controller", "--port", "1", "--device", "0", "--type", "hdd", "--medium", "none")
          end
        end

        def read_persistent_storage(location)
          ## Ensure previous operations are complete - bad practise yes, not sure how to avoid this:
          sleep 3
          info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
          info.split("\n").each do |line|
            return $1.to_s if line =~ /^"SATA Controller-1-0"="(.+?)"$/
          end
          nil
        end

        def identical_files(file1, file2)
          return File.identical?(Pathname.new(file1).realpath, Pathname.new(file2).realpath)
        end

      end
    end
  end
end

