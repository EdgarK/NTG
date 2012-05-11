# this would be a translate script to make google.csv from folder of nokia vcf's
require 'csv'

def log(string)
  puts string
end

def define(name, &block)
  self.class.send('define_method', name, &block)
end

class GoogleContactList
  def initialize(contacts)
    @contacts = Array(contacts)
  end

  def to_csv(filename)
    CSV.open(filename, "wb") do |line|
      line << self.class.column_names
      @contacts.each do |contact|
        line << contact.data
      end
    end
  end

  def self.column_names
    ["Name", "Given Name", "Additional Name", "Family Name", "Yomi Name", "Given Name Yomi",
      "Additional Name Yomi", "Family Name Yomi", "Name Prefix", "Name Suffix", "Initials",
      "Nickname", "Short Name", "Maiden Name", "Birthday", "Gender", "Location",
      "Billing Information", "Directory Server", "Mileage", "Occupation", "Hobby",
      "Sensitivity", "Priority", "Subject", "Notes", "Group Membership", "E-mail 1 - Type",
      "E-mail 1 - Value", "Phone 1 - Type", "Phone 1 - Value", "Phone 2 - Type",
      "Phone 2 - Value", "Phone 3 - Type", "Phone 3 - Value", "Phone 4 - Type", 
      "Phone 4 - Value", "Phone 5 - Type", "Phone 5 - Value", "Address 1 - Type", 
      "Address 1 - Formatted", "Address 1 - Street", "Address 1 - City", "Address 1 - PO Box",
      "Address 1 - Region", "Address 1 - Postal Code", "Address 1 - Country",
      "Address 1 - Extended Address", "Organization 1 - Type", "Organization 1 - Name",
      "Organization 1 - Yomi Name", "Organization 1 - Title", "Organization 1 - Department",
      "Organization 1 - Symbol", "Organization 1 - Location", 
      "Organization 1 - Job Description", "Website 1 - Type", "Website 1 - Value"]
  end
end

class GoogleContact
  attr_reader :data
  def initialize(nokia_contact = nil)
    @data = Array.new(58,'')
    GoogleContactList.column_names.each_with_index do |index, name|
      define('name') do
        @data[index]
      end
      define('name=') do |value|
        @data[index] = value
      end
    end
    from_nokia(nokia_contact) if nokia_contact
  end

  def from_nokia(contact)
    GoogleContactList.column_names.each_with_index do |name, index|
      @data[index] = contact.send(name) if contact.defined?(name)
    end
  end
end

class NokiaContact

  def initialize(vcf)
    @data = {}
    @nokia_data = {}
    parce(vcf)
  end


  def self.column_names
    {'NICKNAME' => 'Nickname', 'TITLE' => 'Organization 1 - Title', 'FN' => 'Name Prefix', 'ORG' => 'Organization 1 - Name', 
      'EMAIL' => 'E-mail 1 - Value', 'URL' =>  'Website 1 - Value', 'N' => false, 'TEL' => false, 'ADR' => false}
  end

  def self.tel_names
    {'VOICE' => 'Prone 1 - Value', 'HOME' => 'Phone 2 - Value', 'WORK' => 'Phone 4 -Value','CELL' => 'Phone 3 - Value', 'FAX' => 'Phone 5 - Value'}
  end

  def defined?(name)
    @data[name] || @nokia_data[name]
  end

  private 
  def parce(vcf)
    vcf.each_line do |line|
      log "now parsing \"#{line}\""
      name, value = col_name(line), col_value(line)
      log "  name is \"#{name}\" and value is \"#{value}\""
      if NokiaContact.column_names.keys.include?(name) && NokiaContact.column_names[name]
        google_name = NokiaContact.column_names[name]
        log "    google_name is \"#{google_name}\""
        def_data_accessor google_name, value.sub(';','')
        def_nokia_accessor name, value.sub(';','')
      elsif self.class.column_names.keys.include? name
        if name == 'ADR'
          log "parcing address"
          parce_adr value
        elsif name == 'N'
          log "parcing name"
          parce_n value
        elsif name == 'TEL'
          log "parsing phone"
          parce_tel line, value
        end
        def_nokia_accessor name, value
      end
    end
  end

  def parce_adr(line)
    adr = {}
    s, adr['Formatted'], adr['Street'],adr['City'],adr['Region'],adr['Postal Code'],adr['Country'] = *(line.split ';')

    adr.each do |key, value|
      name = "Address 1 - #{key}"
      def_data_accessor name, value
    end

  end

  def parce_tel(line, value)
    @ph_n ||= 1
    type = line.match(/(?:[-A-Z]+;*([-A-Z]+):)(?:.*)/)[1].capitalize
    type = "Main" if type == 'Pref'
    name = "Phone #{@ph_n} - "
    ph_type = "#{name}Type" 
    ph_val = "#{name}Value"
    def_data_accessor ph_type, type
    def_data_accessor ph_val, value
    @ph_n += 1
  end

  def parce_n(line)
    name = {}
    name['Family Name'],name['Given Name'] = *(line.split ';')
    name['Name'] = "#{name['Family Name']} #{name['Given Name']}".strip

    name.each do |key, value|
      def_data_accessor(key, value)
    end

  end

  def col_name(line)
    line.match(/([-A-Z]+)[:;]/)[1]
  end

  def col_value(line)
    line.match(/(?:(?:[-A-Z]+;)*[-A-Z]+:)(.*)/)[1].sub("\r","")
  end

  def def_data_accessor(name, value = nil)
    def_accessor "", name, value
  end

  def def_accessor(type,name,value = nil)
    define name do
      instance_variable_get("@#{type}data")[name]
    end
    define "#{name}=" do |val|
      instance_variable_get("@#{type}data")[name] = val
    end
    instance_variable_get("@#{type}data")[name] = value if value
  end

  def def_nokia_accessor(name, value = nil)
    def_accessor "nokia_", name, value
  end

end
