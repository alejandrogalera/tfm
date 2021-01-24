#https://www.youtube.com/watch?v=P8GmToGMeEQ&feature=emb_logo
import sys, webbrowser, pyperclip

#pass it as an argument
#copy i from the list

if (len(sys.argv)>1):
    location = ' '.join(sys.argv[1:])
else:
    location = pyperclip.paste()


webbrowser.open('https://www.google.es/maps/place/'+location)