require 'tty-prompt'
require 'rest-client'
require 'json'
require 'pry'

# welcome message for the opening of the app
class Welcome
  def self.welcome
    puts "👩‍⚕️ Welcome to Find my Doctor 👨‍⚕️"
    puts "This app will help you find a specialized doctor near your location."
    self.login
  end

  # login options for the start of the app
  def self.login
    prompt = TTY::Prompt.new
    choice = prompt.select(PASTEL.blue.bold("What do you wish to do?"), "Login", "Create New User", "Exit")
      if choice == "Login"
        self.existing_user
      elsif choice == "Create New User"
        self.new_user
      elsif choice == "Exit"
        puts ""
        abort("Have a healthy day! 😊
        ")
      end
  end
  
  # option if user exists
  def self.existing_user
    prompt = TTY::Prompt.new
    username = prompt.ask(PASTEL.blue.bold('Username:'))
    password = prompt.mask(PASTEL.blue.bold('Password:'))
    $user = User.find_by(username: username, password: password)
    if $user
      puts "
      "
      puts "_" * 50
      $user.menu
    else
      puts PASTEL.red.bold("Incorrect Username/Password. 😔")
      puts ""
      sleep (0.5)
      puts PASTEL.blue.bold("Try Again!")
      sleep (0.5)
      puts ""
      self.login 
    end
  end

  # option if new user
  def self.new_user
    prompt = TTY::Prompt.new
    username = prompt.ask(PASTEL.blue.bold('Create Username:'), required: true)
    if User.find_by(username: username) != nil 
      puts PASTEL.red.bold("Sorry this username is taken.")
      puts ""
      puts PASTEL.blue.bold("Please enter a new username.")
      self.new_user
    else
      password = prompt.mask(PASTEL.blue.bold('Create Password:'))
      if password == nil 
        puts ""
        puts PASTEL.red.bold("Please enter at least one letter.")
        puts PASTEL.red.bold("Yes we know that this is not very secure.")
        puts ""
        self.new_user
      else
        $user = User.create(username: username, password: password)
        puts "
        "
        puts "_" * 50
        $user.menu
      end
    end
  end

  # options for when choosing new doctor
  def self.new_doctor
    prompt = TTY::Prompt.new
    specialty = prompt.select(PASTEL.blue.bold("Which specialty are you looking for?"), %w(
    Unsure?
    Allergist
    Anesthesiologist
    Cardiologist
    General-Dentist
    Dermatologist
    Emergency-Medicine-Doctor
    Family-Practitioner 
    Gastroenterologist
    Geriatrics
    Internist
    Obstetrics-Gynecologist
    Oncologist
    Ophthalmologist
    Neurologist
    Neurosurgeon
    Pediatrician
    Physical-Therapist
    Psychiatrist
    Pulmonologist
    Diagnostic-Radiologist
    Urologist
    General-Surgeon
    Orthopedic-Surgeon
    Return
    ))
    if specialty == "Return"
      puts ""
      puts "_" * 50
      $user.menu
    elsif specialty == "Unsure?"
      hurt = prompt.ask(PASTEL.blue.bold("What is hurting?"))
      hurt = hurt.downcase.singularize
      specialty = nil 
      self.location(specialty, hurt)
    else
      hurt = nil
      self.location(specialty, hurt)
    end
  end

  # helper method that asks for miles and location
  def self.location(specialty, hurt)
    prompt = TTY::Prompt.new
    miles = prompt.ask(PASTEL.blue.bold("How many miles is your search? (Within 100)"))
    if miles.to_i > 0
      miles = miles.to_i.clamp(1, 100)
      miles = miles.to_s
    else
      puts PASTEL.red.bold("Please put in a number between 1-100.")
      puts ""
      puts "_" * 50
      self.new_doctor
    end
    zip_code = prompt.ask(PASTEL.blue.bold("What is the location?"))
    zip_code == nil ? self.new_doctor :
    self.chain_start(zip_code, specialty, miles, hurt)
  end

  # calls API and returns a hash starting from the data
  def self.get_doctor(zip_code, specialty, miles, hurt)

    Geokit::Geocoders::GoogleGeocoder.api_key = ENV['APIGO']
    a=Geokit::Geocoders::GoogleGeocoder.geocode zip_code
    ll = a.ll
    type = ""
    if specialty
      type = "specialty_uid=#{specialty.downcase}"
    else
      type = "query=#{hurt}"
    end
    begin
    response = RestClient.get("https://api.betterdoctor.com/2016-03-01/doctors?#{type}&sort=best-match-asc&location=#{ll}%2C#{miles}&user_location=#{ll}&skip=0&limit=15&user_key=#{ENV['APIDO']}")
    rescue
      puts ""
      puts PASTEL.red.bold("SORRY SERVICE TEMPORARILY UNAVAILABLE")
      puts ""
      puts "_" * 50
      $user.menu
    end
    response_hash = JSON.parse(response)
    response_hash["data"]
  end

  #class variable that stores iterated doctors with the info we like
  @@x = []

  # iterates through doctors and stores info we like to @@x
  def self.doctor_info(zip_code, specialty, miles, hurt)
    self.get_doctor(zip_code, specialty, miles, hurt).each do |doctor|
      specialties = doctor["specialties"].map {|s| s["name"]}.join(", ")
      phone = doctor["practices"][0]["phones"][0]["number"]
      address = []
      address << doctor["practices"][0]["visit_address"]["street"]
      address << doctor["practices"][0]["visit_address"]["city"]
      address << doctor["practices"][0]["visit_address"]["state"]
      address << doctor["practices"][0]["visit_address"]["zip"]
      address = address.join(", ")
      name = []
      name << doctor["profile"]["first_name"]
      name << doctor["profile"]["last_name"]
      name = name.join(" ")
      title = doctor["profile"]["title"]
      insurances = doctor["insurances"].map {|insurance| insurance["insurance_provider"]["name"]}.uniq
      insurances = insurances.join(", ")
      rating = doctor["ratings"][0]["rating"].to_f unless doctor["ratings"][0].nil?
      #Doctor.new(name, phone, address, specialties, insurances)
      @@x << Doctor.new(name: name, phone: phone, address: address, specialties: specialties, insurances: insurances, rating: rating, title: title)
    end
    @@x
  end

  # making @@x readable
  def self.x
    @@x
  end

  # runs doctor_info so @@x has the info and then runs show_doctors
  def self.chain_start(zip_code, specialty, miles, hurt)
    self.doctor_info(zip_code,specialty, miles, hurt)
    self.show_doctors
  end

  # shows a list of doctors and when chosen you can view info and either choose save or return to previous menu
  def self.show_doctors
    names = self.x.map {|doctor| doctor["name"] + " #{doctor.title}" + " #{doctor.rating ? "-" : "- No Ratings"} #{doctor.rating}"}
    prompt = TTY::Prompt.new
    choice = prompt.select(PASTEL.blue.bold("Here are the doctors near this location")) do |menu|
      names.each {|name| menu.choice name}
      menu.choice "Return"
    end
    if choice == "Return"
      @@x = []
      puts ""
      puts "_" * 50
      self.new_doctor
    elsif
      our_doc = self.x.select {|doctor| doctor.name == choice.split[0...2].join(" ")}
      puts "
      "
      puts PASTEL.cyan.bold("Name:") + " #{our_doc[0].name} #{our_doc[0].title}"
      puts PASTEL.cyan.bold("Phone Number:") + " #{our_doc[0].phone}"
      puts PASTEL.cyan.bold("Address:") + " #{our_doc[0].address}"
      puts PASTEL.cyan.bold("Specialties:") + " #{our_doc[0].specialties}"
      puts PASTEL.cyan.bold("Accepted Insurances:") + " #{our_doc[0].insurances}"
    end
    choice = prompt.select("", "Save", "Return", "Main Menu")
    if choice == "Save"
      doc = self.find_or_create(our_doc[0])
      self.find_my_doc(doc)
      puts ""
      puts "_" * 50
      @@x = []
      $user.menu
    elsif choice == "Return"
      puts ""
      puts "_" * 50
      self.show_doctors
    elsif choice == "Main Menu"
      puts ""
      puts "_" * 50
      @@x = []
      $user.menu
    end
  end

  # helper method to see if doctor was previously saved or not (if not then it will save new doctor)
  def self.find_or_create(doctor)
    if Doctor.find_by(name: doctor.name, phone: doctor.phone)
      Doctor.find_by(name: doctor.name, phone: doctor.phone)
    else
      doctor.save
      $user.doctors.reload
      Doctor.find_by(name: doctor.name, phone: doctor.phone)
    end
  end

  # helper method to see if you have already saved doctor or not (if not creates new MyDoctor)
  def self.find_my_doc(doctor)
    if MyDoctor.find_by(user_id: $user.id, doctor_id: doctor.id)
      puts PASTEL.red.bold("Doctor has already been saved.")
    else
      MyDoctor.create(user_id: $user.id, doctor_id: doctor.id)
      $user.my_doctors.reload 
      $user.reload
      puts PASTEL.green.bold("Doctor is saved.")
      MyDoctor.find_by(user_id: $user.id, doctor_id: doctor.id)
    end
  end


end

