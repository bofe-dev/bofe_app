<h1 align="center"><img height="36" src="https://about.bofe.app/icon.svg"/>&nbsp;<b>Bofe App</b></h1>

<p align="center">Kanban style boards.</p>

<p align="center">
  <a href="https://github.com/javierEd/bofe_app/blob/main/LICENSE">
    <img
      src="https://img.shields.io/github/license/javierEd/bofe_app?logo=open-source-initiative&logoColor=white&style=flat-square"
      alt="license"
    /></a>
  <a href="https://github.com/javierEd/bofe_app/commits/main">
    <img
      src="https://img.shields.io/github/last-commit/javierEd/bofe_app?logo=git&logoColor=white&style=flat-square"
      alt="last commit"
    /></a>
  <a href="https://github.com/javierEd/bofe_app/actions/workflows/ci.yaml">
    <img
      src="https://img.shields.io/github/actions/workflow/status/javierEd/bofe_app/ci.yaml?label=CI&logo=github&style=flat-square"
      alt="CI"
    /></a>
  <a href="https://github.com/javierEd/bofe_app/actions/workflows/cd.yaml">
    <img
      src="https://img.shields.io/github/actions/workflow/status/javierEd/bofe_app/cd.yaml?label=CD&logo=github&style=flat-square"
      alt="CD"
    /></a>
  <a href="https://github.com/javierEd/bofe_app/releases/latest">
    <img
      src="https://img.shields.io/github/v/release/javierEd/bofe_app?include_prereleases&logo=rocket&logoColor=white&style=flat-square"
      alt="release"
    /></a>
</p>

With **Bofe** you can easily build kanban style boards for your projects, personal workflows, or just for fun.

> [!NOTE]
> This repository contains the frontend (mobile/web) application of the project.
> - To see the backend, go to [github.com/javierEd/bofe](https://github.com/javierEd/bofe).

## Features

- Create, manage and share **Boards**.
- Add, rename and reorder **Lists** to match any process (like To-Do, Doing, Done).
- Write **Cards** and move then between lists with smooth drag-and-drop gestures.
- Create **Labels** and assign them to your cards.

### Build Requirements

- Dart 3.11.x
- Flutter 3.41.x

## Environment variables

| Name                | Type   | Default               |
| ------------------- | ------ | --------------------- |
| API_URL             | String | https://api.bofe.app/ |
| APP_TOKEN           | String |                       |
| APP_URL             | String | https://bofe.app/     |
| MAX_FILE_SIZE_BYTES | Number | 104857600             |
| WEBSOCKET_URL       | String | wss://api.bofe.app/   |

## License

This project is open-source and available under the GNU Affero General Public License v3.0 (AGPL v3). Please see the [LICENSE](https://github.com/javierEd/bofe_app/blob/main/LICENSE) file for more details.
