import glob

# do not clobber mobile_5c.asm, it has Battle Tower stuff for some ungodly reason
exceptions = ['mobile/mobile_5c.asm']
mobilefilenames = glob.glob('mobile/*.asm')
printerfilenames = glob.glob('engine/printer/*.asm')
linkfilenames = glob.glob('engine/link/*.asm')

homefiles = ['serial.asm', 'mobile.asm', 'printer.asm']

#TODO: Macros, Constants, RAM, then Engine/battle/ and PokemonCenter2F
# anything marked 'unreferenced'

for filename in filenames:

	print('Update', filename)

	with open(filename, 'r', encoding='utf8') as file:
		lines = file.readlines()

	with open(filename, 'w', encoding='utf8') as file:
		for line in lines:
			if line in ['\tdb 100 ; unknown 1\n', '\tdb 5 ; unknown 2\n']:
				continue
			if line == '\t;   hp  atk  def  spd  sat  sdf\n':
				file.write('\tevs  0,   0,   0,   0,   0,   0\n')
			file.write(line)