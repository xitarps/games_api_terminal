require 'net/http'
require 'json'
require 'byebug'

options = ['adicionar jogo', 'consultar jogos', 'atualizar infos de um jogo', 'excluir jogo' ]
options.unshift 'sair'
url = URI('https://x-games-api.herokuapp.com/api/v1/games')
continue = true

title = <<-EOF
  __ _  __ _ _ __ ___   ___  ___     __ _ _ __ (_)
 / _` |/ _` | '_ ` _ \\ / _ \\/ __|   / _` | '_ \\| |
| (_| | (_| | | | | | |  __/\\__ \\  | (_| | |_) | |
 \\__, |\\__,_|_| |_| |_|\\___||___/___\\__,_| .__/|_|
 |___/                         |_____|   |_|

EOF


def read_games(url, pretty_print: true)
  res = Net::HTTP.get(url)
  json_res = JSON.parse(res, symbolize_names: true)
  data = json_res[:data]
  games = data[:games]

  if pretty_print
    puts 'listando jogos...'

    games.each.with_index do |game,index|
      puts "#{index+1} - #{game[:name]}, genero: #{game[:genre]}"
    end

    sleep 4
  else
    games
  end

end

def delete_game(url)
  puts 'listando jogos para deleção...'
  games = read_games(url, pretty_print: false).map { |game| {id: game[:id], 
                                                            name: game[:name]}}

  games.each.with_index do |game,index|
    puts "#{index+1} - #{game[:name]}"
  end

  puts "\nDigite o numero do jogo a ser excluído"
  delete_index = gets.chomp.to_i - 1
  game_id_to_delete = games[delete_index][:id]

  puts "excluindo #{games[delete_index][:name]}...\n"
  res = Net::HTTP.new(url.host).delete("#{url.path}/#{game_id_to_delete}")

  json_res = JSON.parse(res.body, symbolize_names: true)

  sleep 2
  puts json_res[:message]
  sleep 3
end

def create_game(url)
  game_data = {game: {} }

  puts 'Digite um nome parao jogo:'
  name = gets.chomp
  game_data[:game][:name] = name

  puts "\nDigite de qual gênero se trata o jogo:"
  genre = gets.chomp
  game_data[:game][:genre] = genre

  puts "Adicionando jogo..."


  res = Net::HTTP.post(url, game_data.to_json,
                       "Content-Type": "application/json")

  json_res = JSON.parse(res.body, symbolize_names: true)

  success = res.is_a?(Net::HTTPSuccess)

  puts "#{json_res[:name]} adicionado com sucesso " if success
  puts "erro ao adicionar" unless success
  sleep 3
end

def update_game(url)
  puts 'listando jogos ...'
  games = read_games(url, pretty_print: false).map { |game| {id: game[:id], 
                                                            name: game[:name]}}

  games.each.with_index do |game,index|
    puts "#{index+1} - #{game[:name]}"
  end

  puts "\nDigite o numero do jogo a ser atualizado"
  update_index = gets.chomp.to_i - 1
  game_id_to_update = games[update_index][:id]
  game_data = games[update_index]

  puts "digite novo nome do jogo(ou deixe vazio para não modificar)"
  new_name = gets.chomp
  games[update_index][:name] = new_name unless new_name.empty?

  puts "digite novo gênero do jogo(ou deixe vazio para não modificar)"
  new_genre = gets.chomp
  games[update_index][:genre] = new_genre unless new_genre.empty?

  game_data = { game: games[update_index].except(:id) }

  puts "alterando #{games[update_index][:name]}...\n"

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  res = http.send_request('PUT',
                          "/api/v1/games/#{game_id_to_update}",
                          game_data.to_json,
                          initheader = { 'Content-Type': 'application/json'})

  json_res = JSON.parse(res.body, symbolize_names: true)

  sleep 2
  success = res.is_a?(Net::HTTPSuccess)

  puts "#{json_res[:name]} atualizado com sucesso " if success
  puts "erro ao atualizar" unless success
  sleep 3
end

while continue
  system('clear')
  puts title
  puts "Escolha um numero de uma opção"

  options.each.with_index{|option,index| puts "#{index} - #{option}" }

  option = gets.chomp.to_i

  read_games(url) if option == options.index('consultar jogos')
  delete_game(url) if option == options.index('excluir jogo')
  create_game(url) if option == options.index('adicionar jogo')
  update_game(url) if option == options.index('atualizar infos de um jogo')

  continue = false if option.zero?
end
