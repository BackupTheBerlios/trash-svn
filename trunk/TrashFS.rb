#!/usr/bin/env ruby

class VFSError < String
end


class VirtualFS

  # root directory and current working directory
  attr_reader   :root
  attr_accessor :cwd
  

  def initialize(initial_root)
    @cwd = @root = initial_root
  end


  # resolves a path, whether absolute or relative to the CWD
  def dir(path, ignore_last=false)
    return root.relative($1, ignore_last) if path =~ /^\/+(.*)/

    return cwd.relative(path, ignore_last)
  end
end


class VirtualDir
  attr_reader :path, :name, :parent, :children

  def initialize(path, name, parent)
    @path = path
    @name = name
    @parent = parent
    @children = Hash.new

    # make sure the specified path exists 
    begin
      dir = Dir.new( path )
      dir.close
    rescue
      throw :error, VFSError.new("Local filesystem error: #$!")
    end

  end

  # recursively builds this dir's full virtual path
  def virtual_path()
    if parent.nil?
      "/"
    else
      parent.virtual_path + "#{name}/"
    end
  end


  # recursively traverses the path structure relative to this dir
  # and returns the resulting VirtualDir object
  # if ignore_last=true, ignore the last dir specified in the relative path
  #                      and return its parent.
  #                      this is useful is one wishes to create a new directory
  def relative(rel_path, ignore_last=false)

    rel_path = '' if rel_path.nil?
    
    # rel_path is of the form "d1[/d2/d3...]"
    # where d1 is a child of this dir
    paths = rel_path.split(/\//)
    
    # terminate when given an empty string
    # resolve '..' and '.' to appropriate dirs
    next_dir = case paths[0]
                 
               when nil, '' then return self
                 
               when '.' then self
                 
               when '..' then parent
                 
               else children[paths[0]]
               end

    if ! ignore_last
      throw( :error, VFSError.new("Directory not found - #{virtual_path + rel_path}") ) if next_dir.nil?
    else
      return self
    end
                   
    # recursion: continue traversing from this child
    return next_dir.relative( paths[(1...paths.size)].join('/') )
    
  end  


  # adds a new virtual directory under this one
  def add_child(new_path, name)

    throw( :error,  VFSError.new("Invalid directory name - #{name}") ) if name =~ /[\/*?]/
    
    throw( :error,  VFSError.new("Directory already exists - #{children[name].virtual_path}") ) if children.has_key?(name)

    @children[name] = VirtualDir.new(new_path, name, self)
  end


  # deletes a directory under this one
  def delete_child(name)

    throw( :error, VFSError.new("Directory not found - #{virtual_path + name}") ) if ! children.has_key?(name)

    children[name].move_to(nil)
    children.delete(name)
  end


  # relocates a directory to be under another one
  def move_to(new_parent)
    
    if new_parent.nil?
      @parent = nil

    elsif new_parent.children.has_key?(self.name) 

      throw( :error, VFSError.new("Directory name already exists - #{ new_parent.children[self.name].virtual_path }") )

    else
      parent.delete_child(self.name)
      @parent = new_parent
      new_parent.children[self.name] = self
    end
    
  end


  # returns a list of virtual subdirectory names under this directory
  def list_subdirs
    return children.values.collect { |c| c.name + '/' }.sort
  end


  # returns a list of filenames under this directory (excluding subdirectories)
  def list_files

    begin

      Dir.open( path ) do |dir|

        return dir.entries.select { |fn| ! FileTest.directory? "#{path}/#{fn}" }.sort
      
      end

    rescue

      throw :error, VFSError.new("Local filesystem error: #$!")

    end

  end
  
  
end


# recursively maps a local dir to a virtual dir
def map_dir_recursive(real_path, virtual_parent, topmost=nil, topmost_virtual_path=nil)
  
  new_dir = virtual_parent.add_child( real_path, if topmost
                                                   topmost_virtual_path.split(/\//).select { |s| s.length > 0 }[-1]
                                                 else
                                                   real_path.split(/\//).select { |s| s.length > 0 }[-1]
                                                 end
                                      )
  
  puts "Mapped #{real_path} to #{new_dir.virtual_path}"                      
  
  Dir.open(real_path) do |dir|
    
    dir.entries.select { |fn| FileTest.directory?( real_path + "/" + fn ) && fn !~ /^.{1,2}$/ }.each do |subdir|
      
      map_dir_recursive(real_path + "/" + subdir, new_dir)
      
    end
    
  end         
  
end


vfs = nil

File.open('vfs') { |f| vfs = Marshal.load(f) } if FileTest.exist?( 'vfs' )

if vfs.nil?
  error = catch( :error ) do
    vfs = VirtualFS.new( VirtualDir.new('fsroot', '/', nil) )
  end
end

if error.kind_of? VFSError
  puts error
  exit -1
end

# use a continuation here so we can break out of the entire while loop
callcc do |quit_program|

  while true
    
    print 'trash> '
    
    error = catch( :error ) do
      
      line = gets.chomp
      
      args = line.split(/ /)

      case args[0]
        
      when 'exit', 'quit' then quit_program.call

      when 'pwd' then puts vfs.cwd.virtual_path

      when 'local' then puts vfs.dir( args[1] ).path

      when 'cd' then vfs.cwd = vfs.dir( args[1] )
       
      when 'ls'
        puts vfs.dir( args[1] ).list_subdirs
        puts vfs.dir( args[1] ).list_files      

      when 'map' then
        recursive = nil
        real_path = nil
        virtual_path = nil

        args[(1...args.size)].each do |a|
          if a == '-R'
            recursive = true
          else
            if real_path.nil?
              real_path = a
            else
              virtual_path = a if virtual_path.nil?
            end
          end
        end

        if real_path.nil?
          puts "map: must specify REAL_PATH"

        else

          # take the real path relative to the cwd's real path
          # if the given real path is relative
          real_path = vfs.cwd.path + "/" + real_path if real_path !~ /^\//

         
          # if no virtual path was specified, default to the same name as the real path
          virtual_path = real_path.split( /\// )[-1] if virtual_path.nil?
         
          if !recursive
            new_dir = vfs.dir(virtual_path, true).add_child( real_path, virtual_path )

            puts "Mapped #{real_path} to #{new_dir.virtual_path}"                      

          else

            map_dir_recursive = proc do |path, virtual_parent, topmost|
              
              new_dir = virtual_parent.add_child( path, if topmost
                                                          virtual_path.split(/\//).select { |s| s.length > 0 }[-1]
                                                        else
                                                          path.split(/\//).select { |s| s.length > 0 }[-1]
                                                        end
                                                  )

              puts "Mapped #{path} to #{new_dir.virtual_path}"                      

              Dir.open(path) do |dir|
                dir.entries.select { |fn| FileTest.directory?( path + "/" + fn ) && fn !~ /^.{1,2}$/ }.each { |subdir| map_dir_recursive.call(path + "/" + subdir, new_dir, false) }
              end         
              
            end

            map_dir_recursive( real_path, vfs.dir(virtual_path, true), true, virtual_path )
          end
          

        end

      when 'unmap' then

        del_dir = vfs.dir(args[1])

        if del_dir == vfs.root
          puts "unmap: cannot unmap /"
        else
          del_dir.parent.delete_child(del_dir.name)
        end

        if del_dir == vfs.cwd
          vfs.cwd = vfs.root
          puts "Changed CWD to /"
        end
        
      else
        puts <<ENDHELP

Commands:
\texit
\t\tend program

\tmap [-R] REAL_PATH [VIRTUAL_PATH]
\t\tcreates a virtual directory, optionally recursively

\tunmap VIRTUAL_PATH
\t\tremoves the virtual directory and all of its subdirectories

\tls [VIRTUAL_PATH]
\t\tlists contents of current directory

\tcd [VIRTUAL_PATH]
\t\tchanges the current working directory

\tpwd
\t\tprints the current working directory

\tlocal [VIRTUAL_PATH]
\t\tprints the local path of the specified virtual path
ENDHELP
      end

    end
    
    puts error if error.kind_of? VFSError

  end

end

File.open('vfs', 'w') { |f| Marshal.dump(vfs, f) }
