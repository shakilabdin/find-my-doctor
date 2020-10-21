require 'pry'
require 'tty-prompt'
class User < ActiveRecord::Base
  has_many :my_doctors 
  has_many :doctors, through: :my_doctors

  # main menu
  def menu
    prompt = TTY::Prompt.new
    choice = prompt.select(PASTEL.blue.bold("Please select an option."), "New Doctor", "My Doctors", "Settings", "Logout")
      if choice == "New Doctor"
        Welcome.new_doctor
      elsif choice == "My Doctors"
        puts ""
        puts "_" * 50
        doctors_list
      elsif choice == "Settings"
        self.settings
      elsif choice == "Logout"
        puts PASTEL.green.bold("Goodbye")
        puts "
        "
        puts "_" * 50
        Welcome.welcome
      end
  end

  # settings that allow you to update password or delete account
  def settings
    prompt = TTY::Prompt.new
    choice = prompt.select(PASTEL.blue.bold("Settings of #{self.username}"), "Change Password", "Delete Account", "Return")
    if choice == "Change Password"
      self.change_password
      puts "
      "
      puts "_" * 50
      self.menu
    elsif choice == "Delete Account"
      self.delete_account
    elsif choice == "Return"
      puts ""
      puts "_" * 50
      self.menu
    end
  end

  # helper method to change password
  def change_password
    prompt = TTY::Prompt.new
    old_password = prompt.mask(PASTEL.blue.bold("Enter old password:"))
    if self.password == old_password
      new_password = prompt.mask(PASTEL.blue.bold("Enter new password:"))
      if new_password == nil 
        puts ""
        puts PASTEL.red.bold("Please enter at least one letter.")
        puts PASTEL.red.bold("Yes we know that this is not very secure.")
        puts ""        
        self.change_password
      else
        self.update(password: new_password)
        self.reload
        puts PASTEL.green.bold("Password has been updated.")
      end
    else
      puts PASTEL.red.bold("Incorrect Password.")
      puts ""
      puts PASTEL.blue.bold("Try Again.")
      puts ""
      self.change_password
    end
  end

  # helper method to delete account
  def delete_account 
    prompt = TTY::Prompt.new
    answer = prompt.select(PASTEL.red.bold("Are you sure you want to delete your account?"), %w(Yes No))
    if answer == "No"
      puts "
      "
      puts "_" * 50
      self.menu
    elsif answer == "Yes"
      puts ""
      puts PASTEL.blue.bold("Your account has been deleted.")
      puts PASTEL.blue.bold("We are sorry to see you go. ✌️")
      $user.destroy
      puts ""
      puts "_" * 50
      Welcome.welcome
    end
  end

  # method that allows user to see any doctors they have saved. when chosen you can view info, delete doctor from list and return to previous menu.
  def doctors_list
    names = self.doctors.map {|doctor| doctor.name + " #{doctor.title}" + " #{doctor.specialties != "" ? "-" : "- No Specialties"} #{doctor.specialties}"}.uniq 
    prompt = TTY::Prompt.new
    if names.length == 0 
      puts "You have no doctors saved."
      puts ""
      puts "_" * 50
      menu
    else
      choice = prompt.select(PASTEL.blue.bold("Here are the doctor(s) you have saved.")) do |menu|
        names.each {|name| menu.choice name}
        menu.choice "Return"
      end
      if choice == "Return"
        puts ""
        puts "_" * 50
        menu 
      elsif
        our_doc = self.doctors.select {|doctor| doctor.name == choice.split[0...2].join(" ")}
        puts "
        "
        puts PASTEL.cyan.bold("Name:") + " #{our_doc[0].name} #{our_doc[0].title}"
        puts PASTEL.cyan.bold("Phone Number:") + " #{our_doc[0].phone}"
        puts PASTEL.cyan.bold("Address:") + " #{our_doc[0].address}"
        puts PASTEL.cyan.bold("Specialties:") + " #{our_doc[0].specialties}"
        puts PASTEL.cyan.bold("Accepted Insurances:") + " #{our_doc[0].insurances}"
      end
    end
    choice = prompt.select("", %w(Delete Return))
    if choice == "Delete"
      delete_me = MyDoctor.find_by(user_id: self.id, doctor_id: our_doc[0].id)
      delete_me.destroy
      self.my_doctors.reload
      self.doctors.reload
      self.reload
      puts ""
      puts "_" * 50
      doctors_list
    elsif choice == "Return"
      puts ""
      puts "_" * 50
      doctors_list
    end
  end


end
