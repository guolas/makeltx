require 'open3'

# -----------------------------------------------------------------------------
def clean_environment
  print "Cleaning the environment..."
  command = "find . -type f"
  command = command << "|grep -v \"stuff\""
  command = command << "|egrep -v \"\.(rb|sh|tex|txt|bib|pdf|eps|png|jpg)$\""
  command = command << "|egrep -v \"\.git\""
  command = command << "|xargs rm -rf"
  Open3.popen2e(command) do |stdin, stdouterr, wait_thread|
    unless wait_thread.value.success?
      puts "\n[ERROR] Error cleaning the environment"
      exit(-2)
    end
  end
  print " [DONE]\n" 
end

# -----------------------------------------------------------------------------
def latex_pass(input_file, pass, last = false)
  print "XeTeX pass [" << pass.to_s << "]..."
  options = "-interaction=nonstopmode"
  Open3.popen2("xelatex", options, input_file) do |stdin, stdout, wait_thread|
    error = false
    stdout.each do |line|
      if error
        puts "    " << line
        error = false if /^l\.\d* / =~ line
        puts "---------------------" unless error
      else
        if /error|^\!/i =~ line
          error = true
        end
        if last
          if /undefined/i =~ line
            puts "    " << line
          end
        end
        if error
          puts "---------------------"
          puts "    " << line
        end
      end 
    end
    unless wait_thread.value.success?
      puts "\n[ERROR] Error in pass [" << pass.to_s << "] of XeTeX"
      puts "        Check <" << input_file << ".log> for more details"
      exit(1)
    end
  end
  print " [DONE]\n"
  STDOUT.sync = true
end

# -----------------------------------------------------------------------------
def bibtex_pass(input_file)
  print "Generating the BibTeX content..."
  Open3.popen2e("bibtex", input_file) do |stdin, stdouterr, wait_thread|
    stdouterr.each do |line|
      if /error/i =~ line
        puts line
      end
    end
#     unless wait_thread.value.success?
#       puts "\nError generating the bibliography"
#       exit(2)
#     end
  end
  print " [DONE]\n"
end

# -----------------------------------------------------------------------------
def glossaries_pass(input_file)
  print "Generating the glossaries..."
  Open3.popen2e("makeglossaries", input_file) do |stdin, stdouterr, wait_thread|
    stdouterr.each do |line|
      if /error/i =~ line
        puts line
      end
    end
    unless wait_thread.value.success?
      puts "\n[ERROR] Error generating the glossaries"
      exit(3)
    end
  end
  print " [DONE]\n"
end
# -----------------------------------------------------------------------------
def check_environment(input_file)
  return File.file?("" << input_file << ".tex")
end

# -----------------------------------------------------------------------------
# SCRIPT
if ARGV.size == 0
  puts "You have to specify AT LEAST one argument"
  exit(-1)
end

if /-c/i =~ ARGV[0]
  puts "Are you sure you want to clean the environment from path:"
  puts "    [" << Dir.pwd << "]"
  print "[y/n]: "
  # Read a character, it seems like this way of reading a char without waiting
  # for a newline is system dependent, and this way is valid for Unix-like OS
  begin
    system("stty raw -echo")
    answer = STDIN.getc
  ensure
    system("stty -raw echo")
    puts
  end
  if /^y$/i.match(answer)
    puts "Cleaning is actually disabled until I fix the way it acts, I don't"
    puts "want to break anything"
#      clean_environment
  end
else
  input_file = ARGV[0]
  puts "Processing <" << input_file << ">"
  unless check_environment(input_file)
    puts "[ERROR] File " << input_file << ".tex does not exist"
    exit(-2)
  end

  puts "Cleaning is actually disabled until I fix the way it works, I don't"
  puts "want to break anything"
#   clean_environment

  # Option to only clean the environment
  latex_pass(input_file, 1)
  bibtex_pass(input_file)
  glossaries_pass(input_file)
  latex_pass(input_file, 2)
  latex_pass(input_file, 3, true)
  puts "[FINISHED]"
end
