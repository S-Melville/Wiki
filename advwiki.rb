require 'sinatra' #allows the web application to run
require 'data_mapper' #allows the application to manage databases
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/advwiki.db") #creates a datebase called "advwiki"
class User
    include DataMapper::Resource #creates the user table with columns
    property :id, Serial
    property :username, Text, :required => true
    property :password, Text, :required => true
    property :date_joined, DateTime
    property :edit, Boolean, :required => true, :default => false
end

DataMapper.finalize.auto_upgrade! #creates the .db file if it doesnt exist already

$myinfo = "Stuart Melville"

@info = ""

helpers do #protects designated aspects of the application from unauthorised access. E.g edit / admin control pages.
    def protected!
        if authorized?
            return
        end
        redirect '/denied'
    end
    
    def authorized?
        if $credentials !=nil
            @Userz = User.first(:username => $credentials[0])
            if @Userz
                if @Userz.edit == true
                    return true
                else
                    return false
                end
            else 
                return false
            end
        end
    end
end    

def readFile(filename)
    info = ""
    file = File.open(filename)
    file.each do |line|
        info = info + line
    end
    file.close
    $myinfo = info
end

get '/' do # directs to home page
	
	info = ""
	len = info.length # counts number of characters in advwiki.txt
	len1 = len
	readFile("advwiki.txt")
	@info = info + "" + $myinfo
	len = @info.length
	len2 = len - 1
	len3 = len2 - len1
	@words = len3.to_s
	
		
	file = File.open("advwiki.txt")
	file.each do |line|
	  info = info + line
	end

	file.close
	$wiki = info

	sentence = $wiki
	splits = sentence.split(" ") #counts number of words in advwiki.txt
	@words2 = splits.length.to_i
  
  erb :home #calls home view
end

get '/about' do #calls about view
  erb :about
end

get '/trailer' do #calls trailer view with embedded youtube video
  erb :trailer
end

get '/edit' do
  protected!
  info = ""
  file = File.open("advwiki.txt")
  file.each do |line|
    info = info + line
    end
    file.close
  @info = info
  
  erb :edit # calls edit view
end

put '/edit' do
    info = "#{params[:message]}"
    @info = info
    file = File.open("advwiki.txt" , "w") #opens advwiki.txt and writes new data to it
    file.puts @info
    file.close
    
    file = File.open("changes.txt" , "a") # opens changes.txt and allows us to add text to it. Won't overwrite.
    username = $credentials [0]
    timenow = Time.now.asctime
    message = "#{username} made changes @ #{timenow} These are the revisions:#{params[:message]}"
    file.puts message #writes the username, and the details of changes made to the wiki to changes.txt. 
    file.close #close changes.txt
    redirect '/' #return user to home page
end

get '/reset_to_default' do #allows user to restore home page data to predetermined text using default.txt file
    
    file = File.open("default.txt", "r") #reads the text default.txt file
    @data = file.read
    file.close
    file = File.open("advwiki.txt", "w") #over writes the text currently in advwiki.txt with that read in default.txt
    file.puts @data
    file.close
   
    redirect '/'
    
end

get '/backup' do # allows user to back up home page text and archive it to a seperate text file

    file = File.open("advwiki.txt", "r") #opens advwiki.txt file and reads the text
    data = file.read
    file.close
    file = File.open("backup.txt", "a") #copies the text in advwiki and writes it to backup.txt
    file.puts data
    file.puts ""
    file.close
    redirect '/'
end

get '/login' do #calls login erb view
  erb :login
end

post '/login' do #redirects to login page and writes the login info to a text file
  $credentials = [params[:username],params[:password]]
  @Users = User.first(:username => $credentials[0])
  if @Users
    if @Users.password == $credentials[1] #username and passwpod must match stored details or redirected to wrong account erb
      file = File.open("login_record.txt", "a") #opens login record to allow new data to be added
      username = $credentials [0]
      timenow = Time.now.asctime
      message = "#{username} logged in at #{timenow}" #ruby creates a message with username and the current time
      file.puts message #outputs message to login record text file and closes it
      file.close
      redirect '/'
    else
      $credentials = ['','']
      redirect '/wrongaccount'
    end
  else
    $credentials = ['','']
    redirect '/wrongaccount'
  end
end

get '/wrongaccount' do
  erb :wrongaccount
end

get '/user/:uzer' do
  @Userz = User.first(:username => params[:uzer]) 
  if @Userz != nil #if user succesfully logs in , preofile.erb runs. If login fails redirected to noaccount.erb
    erb :profile 
  else
    redirect '/noaccount' 
  end
end

get '/createaccount' do # directs users to create account page
  erb :createaccount
end

post '/createaccount' do # allows users to create a new account
  n = User.new
  n.username = params[:username]
  n.password = params[:password]
  if n.username == "Admin" and n.password == "admin" #to login is administrator username must = Admin and pw must =admin
    n.edit = true end
  n.save
  redirect "/" 
end

get '/logout' do #once logged out redirected to homepage
  $credentials = ["",""]
  redirect '/'
end

put '/user/:uzer' do 
  n = User.first(:username => params[:uzer])
  n.edit = params[:edit] ? 1 : 0
  n.save
  redirect '/'
end

get '/admincontrols' do
    protected! # only admin can access admincontrols. If another user attempts to access redirected to denied.erb
    @list2 = User.all :order => :id.desc
    erb :admincontrols
end

get '/user/delete/:uzer' do
    protected! #helpers
    n = User.first(:username => params[:uzer])
    if n.username == "Admin" #Allows admin to delete user accounts
        erb :denied
    else
        n.destroy
        @list2 = User.all :order => :id.desc
        erb :admincontrols
    end
end

get '/strategy' do # calls strategy view
	erb :strategy
end

get '/notfound' do
  erb :notfound
end

not_found do
    status 404
    redirect'/notfound'
  end
  
get '/noaccount' do
    erb :noaccount
end

get '/denied' do
    erb :denied
end