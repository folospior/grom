package main

import (
	"fmt"
	"log/slog"
	"os"
	"os/signal"

	"github.com/bwmarrin/discordgo"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	token := os.Getenv("BOT_TOKEN")

	discord, err := discordgo.New("Bot " + token)
	if err != nil {
		slog.Error("couldn't create the discord session", "err", err)
		os.Exit(1)
	}

	discord.AddHandler(onReady)
	discord.AddHandler(onInteractionCreate)

	err = discord.Open()
	if err != nil {
		slog.Error("couldn't start the gateway", "err", err)
		os.Exit(1)
	}
	defer discord.Close()

	signalInterrupt := make(chan os.Signal, 1)
	signal.Notify(signalInterrupt, os.Interrupt)
	<-signalInterrupt
}

func onReady(discord *discordgo.Session, ready *discordgo.Ready) {
	slog.Info("Ready!")

	commands := []*discordgo.ApplicationCommand{
		{
			Name:        "ping",
			Description: "Ping-pong! 🏓",
		},
	}

	_, err := discord.ApplicationCommandBulkOverwrite(ready.Application.ID, "", commands)
	if err == nil {
		slog.Info(fmt.Sprintf("Overwrote the commands for %s", ready.Application.ID))
	} else {
		slog.Error("Couldn't bulk overwrite global commands", "err", err)
	}

	err = discord.UpdateWatchStatus(0, "the gateway connection")
	if err != nil {
		slog.Error("Couldn't update the status", "err", err)
	}
}

func onInteractionCreate(discord *discordgo.Session, interactionCreate *discordgo.InteractionCreate) {
	if interactionCreate.Type == discordgo.InteractionApplicationCommand {
		onCommandExecute(discord, interactionCreate)
	}
}

func onCommandExecute(discord *discordgo.Session, interactionCreate *discordgo.InteractionCreate) {
	if interactionCreate.ApplicationCommandData().CommandType == discordgo.ChatApplicationCommand {
		onSlashCommandExecute(discord, interactionCreate)
	}
}

func onSlashCommandExecute(discord *discordgo.Session, interactionCreate *discordgo.InteractionCreate) {
	switch interactionCreate.ApplicationCommandData().Name {
	case "ping":
		onPingCommand(discord, interactionCreate)
	}
}

func onPingCommand(discord *discordgo.Session, interactionCreate *discordgo.InteractionCreate) {
	response := &discordgo.InteractionResponse{
		Type: discordgo.InteractionResponseChannelMessageWithSource,
		Data: &discordgo.InteractionResponseData{
			Content: "Pong!",
		},
	}

	discord.InteractionRespond(interactionCreate.Interaction, response)
}
