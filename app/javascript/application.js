import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import "@hotwired/turbo-rails"
eagerLoadControllersFrom("controllers", application)
import "controllers"
import "chartkick"
import "Chart.bundle"
