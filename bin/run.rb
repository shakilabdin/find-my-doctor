require_relative '../config/environment'

# starts the app with a banner
Catpix::print_image "./lib/photo/banner4.png", 
# format banner
  :limit_x => 0.8,
  :limit_y => 0.0,
  :center_x => true,
  :center_y => false,
  # :bg => 'white',
  # :bg_fill => true,
  :resolution => 'high'

puts "

"
# computer speaks
`say "Welcome to find My Doctor"`

#runs the Welcome class which starts the app
Welcome.welcome

