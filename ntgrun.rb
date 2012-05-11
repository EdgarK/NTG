require File.expand_path('ntg.rb')

directory, file_path = *ARGV

contacts = []
Dir.glob("#{directory}/*.vcf") do |file| 
  file = File.open(file, "r")
  nc = NokiaContact.new(file)
  gc = GoogleContact.new(nc)
  contacts << gc
  file.close
end
list = GoogleContactList.new contacts
list.to_csv file_path

