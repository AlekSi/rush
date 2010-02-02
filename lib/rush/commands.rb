# The commands module contains operations against Rush::File entries, and is
# mixed in to Rush::Entry and Array.  This means you can run these commands against a single
# file, a dir full of files, or an arbitrary list of files.
#
# Examples:
#
#   box['/etc/hosts'].search /localhost/       # single file
#   box['/etc/'].search /localhost/            # entire directory
#   box['/etc/**/*.conf'].search /localhost/   # arbitrary list
module Rush::Commands
	# The entries command must return an array of Rush::Entry items.  This
	# varies by class that it is mixed in to.
	def entries
		raise "must define me in class mixed in to for command use"
	end

	# Search file contents for a regular expression.  A Rush::SearchResults
	# object is returned.
	def search(pattern)
		results = Rush::SearchResults.new(pattern)
		entries.each do |entry|
			if !entry.dir? and matches = entry.search(pattern)
				results.add(entry, matches)
			end
		end
		results
	end

	# Search and replace file contents.
	def replace_contents!(pattern, with_text)
		entries.each do |entry|
			entry.replace_contents!(pattern, with_text) unless entry.dir?
		end
	end

	# Count the number of lines in the contained files.
	def line_count
		entries.inject(0) do |count, entry|
			count += entry.lines.size if !entry.dir?
			count
		end
	end

    def self.included(base)
       base.extend ExternalCommands
       base.add_methods :vim, :mate
    end

    module ExternalCommands
       def add_methods(*args)
         args.each do |method_name|
           if system "#{method_name} --version > /dev/null 2>&1"
             define_method(method_name) do |*method_args|
               names = entries.map { |f| f.quoted_path }.join(' ')
               system "#{method_name} #{names} #{method_args.join(' ')}"
             end
           end
         end
       end
     end
end
