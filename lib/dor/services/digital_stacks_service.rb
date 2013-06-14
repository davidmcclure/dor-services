require 'net/ssh'
require 'net/sftp'
require 'net/ssh/kerberos'

module Dor
  class DigitalStacksService
    def self.druid_tree(druid)
      File.expand_path('..',DruidTools::Druid.new(druid,'/').path)
    rescue
      raise "Invalid druid: #{id}"
    end
    
    def self.ssh_stacks_client type = nil
      if type == :document_cache
        h = Config.stacks.document_cache_host
        u = Config.stacks.document_cache_user
      else
        h = Config.stacks.host
        u = Config.stacks.user
      end
      yield Net::SSH.start(h, u, :auth_methods => (Config.stacks.ssh_auth || 'publickey').split(','))      
    end
    
    # @param String druid id of the object
    # @return String the directory on the stacks server holding the druid's content
    def self.stacks_storage_dir(druid)
      path = self.druid_tree(druid)

      File.join(Config.stacks.storage_root, path)
    end

    def self.transfer_to_document_store(id, content, filename)
      path = self.druid_tree(id)

      # create the remote directory in the document cache
      remote_document_cache_dir = File.join(Config.stacks.document_cache_storage_root, path)

      content_io = StringIO.new(content)
      
      self.ssh_stacks_client(:document_cache) do |ssh|
        ssh.exec! "mkdir -p #{remote_document_cache_dir}"
        ssh.sftp.upload!(content_io,File.join(remote_document_cache_dir,filename))
      end
    end

    def self.remove_from_stacks(id, files)
      unless files.empty?
        remote_storage_dir = self.stacks_storage_dir(id)
        self.ssh_stacks_client do |ssh|
          files.each { |file| ssh.sftp.remove!(File.join(remote_storage_dir,file)) }
        end
      end
    end

    # @param [String] id object pid
    # @param [Array<Array<String>>] file_map an array of two string arrays.  Each inner array represents old-file/new-file mappings.  First string is the old file name, second string is the new file name. e.g:
    #   [ ['src1.file', 'dest1.file'], ['src2.file', 'dest2.file'] ]
    def self.rename_in_stacks(id, file_map)
      unless file_map.empty?
        remote_storage_dir = self.stacks_storage_dir(id)
        self.ssh_stacks_client do |ssh|
          file_map.each { |source,dest| ssh.sftp.rename!(File.join(remote_storage_dir,source),File.join(remote_storage_dir,dest)) }
        end
      end
    end

    def self.shelve_to_stacks(id, files)
      unless files.empty?
        druid = DruidTools::Druid.new(id,Config.stacks.local_workspace_root)
        remote_storage_dir = self.stacks_storage_dir(id)
        self.ssh_stacks_client do |ssh|
          # create the remote directory on the digital stacks
          ssh.exec! "mkdir -p #{remote_storage_dir}"
          # copy the contents for the given object from the local workspace directory to the remote directory
          uploads = files.collect do |file|
            local_file = druid.find_content(file)
            ssh.sftp.upload!(local_file, File.join(remote_storage_dir,file))
          end
          uploads.each { |upload| upload.wait }
        end
      end
    end
  end
  
end
